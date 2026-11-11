<#
.SYNOPSIS
    Uploads the sentinel/ folder to HCP Terraform as a new policy set version.

.DESCRIPTION
    The HCP Terraform Free tier does not allow VCS-backed policy sets, so the
    policy set is "Automated" (API-managed). GitHub stays the source of truth:
    this script packages sentinel.hcl and the *.sentinel policies from the
    checked-out repo and uploads them as a new version.

      1. runs `sentinel test` (nothing untested is uploaded)
      2. finds the policy set by name
      3. packages sentinel/ into a .tar.gz (test/ folder excluded)
      4. creates a policy set version and uploads the package
      5. waits until HCP reports the version as ready

    Run it from main after a policy PR is merged, so HCP enforces exactly what
    was reviewed.

    The HCP token is read from $env:TFE_TOKEN or from the file written by
    `terraform login`. The token is never printed.

.EXAMPLE
    .\scripts\upload-policies.ps1
#>
param(
    [string] $Organisation = "L00205332",
    [string] $PolicySet    = "atul0012345-sovereignty-policies",
    [switch] $SkipTests
)

$ErrorActionPreference = "Stop"
$api       = "https://app.terraform.io/api/v2"
$jsonApi   = "application/vnd.api+json"
$sentinel  = Join-Path (Split-Path $PSScriptRoot -Parent) "sentinel"

# --- HCP token ---------------------------------------------------------------
$token = $env:TFE_TOKEN
if (-not $token) {
    $credFile = Join-Path $env:APPDATA "terraform.d\credentials.tfrc.json"
    if (-not (Test-Path $credFile)) { throw "No HCP token: run 'terraform login' or set TFE_TOKEN." }
    $token = (Get-Content $credFile -Raw | ConvertFrom-Json).credentials."app.terraform.io".token
}
$headers = @{ Authorization = "Bearer $token" }

# --- 1. Test first -------------------------------------------------------------
if (-not $SkipTests) {
    Push-Location $sentinel
    try {
        sentinel test
        if ($LASTEXITCODE -ne 0) { throw "sentinel test failed: nothing uploaded." }
    } finally { Pop-Location }
}

# --- 2. Find the policy set ------------------------------------------------------
$sets = (Invoke-RestMethod -Method Get -Headers $headers `
          -Uri "$api/organizations/$Organisation/policy-sets?search%5Bname%5D=$PolicySet").data
$set = $sets | Where-Object { $_.attributes.name -eq $PolicySet } | Select-Object -First 1
if (-not $set) { throw "Policy set '$PolicySet' not found in organisation $Organisation." }
Write-Host "Policy set $PolicySet ($($set.id))"

# --- 3. Package ---------------------------------------------------------------------
$package = Join-Path $env:TEMP "atul0012345-policies.tar.gz"
if (Test-Path $package) { Remove-Item $package }
# Windows 10+ ships bsdtar as tar.exe. sentinel.hcl must sit at the archive root.
tar -czf $package -C $sentinel --exclude "./test" --exclude "test" --exclude ".sentinel" .
if ($LASTEXITCODE -ne 0) { throw "Packaging failed." }
Write-Host "Packaged:"
tar -tzf $package | ForEach-Object { Write-Host "  $_" }

# --- 4. Create version + upload --------------------------------------------------------
$version = (Invoke-RestMethod -Method Post -Uri "$api/policy-sets/$($set.id)/versions" `
              -Headers $headers -ContentType $jsonApi).data
Invoke-RestMethod -Method Put -Uri $version.links.upload -ContentType "application/octet-stream" `
    -InFile $package | Out-Null
Write-Host "Uploaded as version $($version.id)"

# --- 5. Wait until ingested ---------------------------------------------------------------
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 2
    $v = (Invoke-RestMethod -Method Get -Uri "$api/policy-set-versions/$($version.id)" -Headers $headers).data
    $status = $v.attributes.status
    if ($status -eq "ready") {
        Write-Host "Policy set version is ready: HCP now enforces this code on the next run." -ForegroundColor Green
        Remove-Item $package
        exit 0
    }
    if ($status -eq "errored") {
        throw "HCP rejected the upload: $($v.attributes.'error-message')"
    }
}
throw "Timed out waiting for the policy set version (last status: $status)."
