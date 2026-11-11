<#
.SYNOPSIS
    Deploys the Sentinel policies in sentinel/ to HCP Terraform, using
    sentinel.hcl as the list of policies and enforcement levels.

.DESCRIPTION
    The HCP Terraform Free tier allows 0 *versioned* policy sets: HCP cannot read
    a policy set from VCS and cannot accept an uploaded folder. It does allow
    individually managed policies attached to a policy set, and those can be
    created and updated through the API. GitHub therefore stays the source of
    truth, and this script syncs the repo into HCP:

      1. runs `sentinel test` (nothing untested is deployed)
      2. reads every policy block (name, source, enforcement_level) from sentinel.hcl
      3. for each policy: creates it in HCP or updates it, attaches it to the
         policy set, and uploads the .sentinel code from the repo
      4. warns about policies in the set that are no longer in sentinel.hcl

    Limitation of individually managed policies: HCP evaluates each policy on
    its own, so sentinel.hcl "param" values and shared modules are not used.
    The policies here only use standard imports and in-code param defaults.

    The HCP token is read from $env:TFE_TOKEN or from the file written by
    `terraform login`. The token is never printed.

.EXAMPLE
    .\scripts\upload-policies.ps1
    .\scripts\upload-policies.ps1 -ParseOnly     # show what would be deployed, no API calls
#>
param(
    [string] $Organisation = "L00205332",
    [string] $PolicySet    = "atul0012345-sovereignty-policies",
    [switch] $SkipTests,
    [switch] $ParseOnly
)

$ErrorActionPreference = "Stop"
$api      = "https://app.terraform.io/api/v2"
$jsonApi  = "application/vnd.api+json"
$sentinel = Join-Path (Split-Path $PSScriptRoot -Parent) "sentinel"

# --- Read sentinel.hcl ------------------------------------------------------------
function Get-PolicyDefinitions {
    $hcl = Get-Content (Join-Path $sentinel "sentinel.hcl") -Raw
    # Strip comments, then match: policy "name" { source = "..." enforcement_level = "..." }
    $hcl = ($hcl -split "`n" | ForEach-Object { ($_ -replace '#.*$', '') }) -join "`n"
    $blocks = [regex]::Matches($hcl, 'policy\s+"(?<name>[^"]+)"\s*\{(?<body>[^}]*)\}')
    foreach ($b in $blocks) {
        $body   = $b.Groups["body"].Value
        $source = [regex]::Match($body, 'source\s*=\s*"(?<v>[^"]+)"').Groups["v"].Value
        $level  = [regex]::Match($body, 'enforcement_level\s*=\s*"(?<v>[^"]+)"').Groups["v"].Value
        if (-not $source) { throw "Policy '$($b.Groups['name'].Value)' has no source in sentinel.hcl" }
        if (-not $level)  { $level = "advisory" }   # Sentinel's default
        $path = Join-Path $sentinel ($source -replace '^\./', '')
        if (-not (Test-Path $path)) { throw "Policy source not found: $path" }
        [pscustomobject]@{ Name = $b.Groups["name"].Value; Path = $path; Level = $level }
    }
}

$policies = @(Get-PolicyDefinitions)
if ($policies.Count -eq 0) { throw "No policy blocks found in sentinel.hcl" }
Write-Host "Policies defined in sentinel.hcl:"
$policies | ForEach-Object { Write-Host ("  {0,-16} {1,-16} {2}" -f $_.Name, $_.Level, (Split-Path $_.Path -Leaf)) }
if ($ParseOnly) { exit 0 }

# --- HCP token ---------------------------------------------------------------------
$token = $env:TFE_TOKEN
if (-not $token) {
    $credFile = Join-Path $env:APPDATA "terraform.d\credentials.tfrc.json"
    if (-not (Test-Path $credFile)) { throw "No HCP token: run 'terraform login' or set TFE_TOKEN." }
    $token = (Get-Content $credFile -Raw | ConvertFrom-Json).credentials."app.terraform.io".token
}
$headers = @{ Authorization = "Bearer $token" }

# --- 1. Test first ----------------------------------------------------------------------
if (-not $SkipTests) {
    Push-Location $sentinel
    try {
        sentinel test
        if ($LASTEXITCODE -ne 0) { throw "sentinel test failed: nothing deployed." }
    } finally { Pop-Location }
}

# --- 2. Find the policy set ---------------------------------------------------------------
$sets = (Invoke-RestMethod -Method Get -Headers $headers `
          -Uri "$api/organizations/$Organisation/policy-sets?search%5Bname%5D=$PolicySet").data
$set = $sets | Where-Object { $_.attributes.name -eq $PolicySet } | Select-Object -First 1
if (-not $set) { throw "Policy set '$PolicySet' not found in organisation $Organisation." }
Write-Host "Policy set $PolicySet ($($set.id))"

# --- 3. Create/update, attach, upload each policy --------------------------------------------
foreach ($p in $policies) {
    $found = (Invoke-RestMethod -Method Get -Headers $headers `
               -Uri "$api/organizations/$Organisation/policies?search%5Bname%5D=$($p.Name)").data |
             Where-Object { $_.attributes.name -eq $p.Name } | Select-Object -First 1

    if ($found) {
        $body = @{ data = @{ type = "policies"; attributes = @{ "enforcement-level" = $p.Level } } } |
                ConvertTo-Json -Depth 10
        $policy = (Invoke-RestMethod -Method Patch -Uri "$api/policies/$($found.id)" -Headers $headers `
                     -ContentType $jsonApi -Body $body).data
        $action = "updated"
    } else {
        $body = @{
            data = @{
                type          = "policies"
                attributes    = @{
                    name                = $p.Name
                    kind                = "sentinel"
                    description         = "Deployed from GitHub: sentinel/$(Split-Path $p.Path -Leaf)"
                    "enforcement-level" = $p.Level
                }
                relationships = @{ "policy-sets" = @{ data = @(@{ id = $set.id; type = "policy-sets" }) } }
            }
        } | ConvertTo-Json -Depth 10
        $policy = (Invoke-RestMethod -Method Post -Uri "$api/organizations/$Organisation/policies" `
                     -Headers $headers -ContentType $jsonApi -Body $body).data
        $action = "created"
    }

    # Attach to the policy set (no effect if it is already attached).
    $attach = @{ data = @(@{ id = $policy.id; type = "policies" }) } | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Method Post -Uri "$api/policy-sets/$($set.id)/relationships/policies" `
        -Headers $headers -ContentType $jsonApi -Body $attach | Out-Null

    # Upload the policy code exactly as it is in the repo.
    Invoke-RestMethod -Method Put -Uri "$api/policies/$($policy.id)/upload" -Headers $headers `
        -ContentType "application/octet-stream" -InFile $p.Path | Out-Null

    Write-Host ("  {0,-16} {1,-8} {2,-16} {3}" -f $p.Name, $action, $p.Level, $policy.id) -ForegroundColor Green
}

# --- 4. Report policies in HCP that are no longer in the repo ---------------------------------
$inSet = (Invoke-RestMethod -Method Get -Headers $headers -Uri "$api/policy-sets/$($set.id)?include=policies").included
$stale = $inSet | Where-Object { $_.type -eq "policies" -and ($policies.Name -notcontains $_.attributes.name) }
foreach ($s in $stale) {
    Write-Host "  WARNING: '$($s.attributes.name)' is in the policy set but not in sentinel.hcl" -ForegroundColor Yellow
}

Write-Host "Done: HCP enforces these policies from the next run." -ForegroundColor Green
