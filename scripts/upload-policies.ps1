<#
.SYNOPSIS
    Deploys the Sentinel policies from the repo to HCP Terraform (Free tier).

.DESCRIPTION
    HCP Terraform Free limits:
      - 0 versioned policy sets  -> no VCS link, no folder upload; policies are
                                    created one by one through the Policies API
      - 1 mandatory policy       -> every mandatory policy in sentinel.hcl is
                                    merged into ONE hard-mandatory bundle by
                                    build-bundle.ps1; advisory policies are
                                    deployed individually

    Steps:
      1. refuses to deploy uncommitted changes (GitHub is the source of truth)
         and records the git commit in each policy's description
      2. runs `sentinel test` on the separate policies
      3. builds the bundle and runs the bundle tests (build-bundle.ps1)
      4. removes policies from the set that are no longer deployed, but ONLY
         with -RemoveStale (otherwise it stops and lists them)
      5. creates or updates the bundle (hard-mandatory) and each advisory policy,
         attaches them to the policy set and uploads their code

    The HCP token is read from $env:TFE_TOKEN or from the file written by
    `terraform login`. The token is never printed.

.EXAMPLE
    .\scripts\upload-policies.ps1 -DryRun        # build + test only, no API calls
    .\scripts\upload-policies.ps1
    .\scripts\upload-policies.ps1 -RemoveStale   # also delete policies no longer in the repo
#>
param(
    [string] $Organisation = "L00205332",
    [string] $PolicySet    = "atul0012345-sovereignty-policies",
    [switch] $DryRun,
    [switch] $RemoveStale,
    [switch] $AllowDirty
)

$ErrorActionPreference = "Stop"
$api      = "https://app.terraform.io/api/v2"
$jsonApi  = "application/vnd.api+json"
$repo     = Split-Path $PSScriptRoot -Parent
$sentinel = Join-Path $repo "sentinel"

# --- 1. Source of truth ------------------------------------------------------------
$dirty = git -C $repo status --porcelain -- sentinel
if ($dirty -and -not $AllowDirty -and -not $DryRun) {
    throw "Uncommitted changes under sentinel/. Commit and merge them first (or use -DryRun):`n$($dirty -join "`n")"
}
$commit = (git -C $repo rev-parse --short HEAD).Trim()
$branch = (git -C $repo rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne "main" -and -not $DryRun) {
    Write-Host "WARNING: deploying from branch '$branch', not main." -ForegroundColor Yellow
}

# --- 2. Test the separate policies ---------------------------------------------------
Push-Location $sentinel
try {
    sentinel test
    if ($LASTEXITCODE -ne 0) { throw "sentinel test failed: nothing deployed." }
} finally { Pop-Location }

# --- 3. Build + test the bundle ----------------------------------------------------------
$build = & (Join-Path $PSScriptRoot "build-bundle.ps1")
$deploy = @([pscustomobject]@{
    Name        = $build.BundleName
    Path        = $build.BundlePath
    Level       = "hard-mandatory"
    Description = "Bundle of $($build.Bundled -join ', ') from GitHub commit $commit (scripts/build-bundle.ps1)"
})
foreach ($a in $build.Advisory) {
    $deploy += [pscustomobject]@{
        Name        = $a.Name
        Path        = $a.Path
        Level       = "advisory"
        Description = "From GitHub commit ${commit}: sentinel/$(Split-Path $a.Path -Leaf)"
    }
}

Write-Host ""
Write-Host "To deploy (commit $commit):"
$deploy | ForEach-Object { Write-Host ("  {0,-24} {1,-16} {2}" -f $_.Name, $_.Level, (Split-Path $_.Path -Leaf)) }
if ($DryRun) { Write-Host "Dry run: no changes made in HCP."; exit 0 }

# --- HCP token ------------------------------------------------------------------------------
$token = $env:TFE_TOKEN
if (-not $token) {
    $credFile = Join-Path $env:APPDATA "terraform.d\credentials.tfrc.json"
    if (-not (Test-Path $credFile)) { throw "No HCP token: run 'terraform login' or set TFE_TOKEN." }
    $token = (Get-Content $credFile -Raw | ConvertFrom-Json).credentials."app.terraform.io".token
}
$headers = @{ Authorization = "Bearer $token" }

# --- Policy set -------------------------------------------------------------------------------
$sets = (Invoke-RestMethod -Method Get -Headers $headers `
          -Uri "$api/organizations/$Organisation/policy-sets?search%5Bname%5D=$PolicySet").data
$set = $sets | Where-Object { $_.attributes.name -eq $PolicySet } | Select-Object -First 1
if (-not $set) { throw "Policy set '$PolicySet' not found in organisation $Organisation." }
Write-Host "Policy set $PolicySet ($($set.id))"

# --- 4. Stale policies (must go first: they may hold the single mandatory slot) ----------------
$inSet = @((Invoke-RestMethod -Method Get -Headers $headers -Uri "$api/policy-sets/$($set.id)?include=policies").included |
           Where-Object { $_.type -eq "policies" })
$stale = @($inSet | Where-Object { $deploy.Name -notcontains $_.attributes.name })
if ($stale.Count -gt 0) {
    if (-not $RemoveStale) {
        $list = ($stale | ForEach-Object { "$($_.attributes.name) ($($_.attributes.'enforcement-level'))" }) -join ", "
        throw "These policies are in HCP but no longer deployed from the repo: $list. Re-run with -RemoveStale to delete them."
    }
    foreach ($s in $stale) {
        Invoke-RestMethod -Method Delete -Uri "$api/policies/$($s.id)" -Headers $headers | Out-Null
        Write-Host ("  {0,-24} deleted (stale)" -f $s.attributes.name) -ForegroundColor Yellow
    }
}

# --- 5. Create/update, attach, upload ------------------------------------------------------------
foreach ($p in $deploy) {
    $found = (Invoke-RestMethod -Method Get -Headers $headers `
               -Uri "$api/organizations/$Organisation/policies?search%5Bname%5D=$($p.Name)").data |
             Where-Object { $_.attributes.name -eq $p.Name } | Select-Object -First 1

    $attributes = @{ "enforcement-level" = $p.Level; description = $p.Description }
    if ($found) {
        $body = @{ data = @{ type = "policies"; attributes = $attributes } } | ConvertTo-Json -Depth 10
        $policy = (Invoke-RestMethod -Method Patch -Uri "$api/policies/$($found.id)" -Headers $headers `
                     -ContentType $jsonApi -Body $body).data
        $action = "updated"
    } else {
        $attributes.name = $p.Name
        $attributes.kind = "sentinel"
        $body = @{
            data = @{
                type          = "policies"
                attributes    = $attributes
                relationships = @{ "policy-sets" = @{ data = @(@{ id = $set.id; type = "policy-sets" }) } }
            }
        } | ConvertTo-Json -Depth 10
        $policy = (Invoke-RestMethod -Method Post -Uri "$api/organizations/$Organisation/policies" `
                     -Headers $headers -ContentType $jsonApi -Body $body).data
        $action = "created"
    }

    $attach = @{ data = @(@{ id = $policy.id; type = "policies" }) } | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Method Post -Uri "$api/policy-sets/$($set.id)/relationships/policies" `
        -Headers $headers -ContentType $jsonApi -Body $attach | Out-Null

    Invoke-RestMethod -Method Put -Uri "$api/policies/$($policy.id)/upload" -Headers $headers `
        -ContentType "application/octet-stream" -InFile $p.Path | Out-Null

    Write-Host ("  {0,-24} {1,-8} {2,-16} {3}" -f $p.Name, $action, $p.Level, $policy.id) -ForegroundColor Green
}

Write-Host "Done: HCP enforces commit $commit from the next run." -ForegroundColor Green
