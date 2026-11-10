<#
.SYNOPSIS
    Destroys the stack through HCP Terraform, then audits AWS for leftovers and drift.

.DESCRIPTION
    The workspace is VCS-driven, so `terraform destroy` from the CLI is not
    allowed (applies must go through HCP). This script uses the HCP Terraform
    API instead:
      1. looks up the workspace
      2. queues a destroy run (plan + Sentinel policy check, like any run)
      3. asks you to type the workspace name to confirm the apply
      4. waits for the run to finish
      5. runs audit-regions.ps1 to prove nothing is left behind

    The HCP token is read from $env:TFE_TOKEN or from the file written by
    `terraform login` (%APPDATA%\terraform.d\credentials.tfrc.json).
    The token is never printed.

.EXAMPLE
    .\scripts\destroy.ps1
    .\scripts\destroy.ps1 -AwsProfile admin
#>
param(
    [string] $Organisation = "L00205332",
    [string] $Workspace    = "atul0012345-sovereignty",
    [string] $AwsProfile,
    [int]    $TimeoutMinutes = 30
)

$ErrorActionPreference = "Stop"
$api = "https://app.terraform.io/api/v2"

# --- HCP token ---------------------------------------------------------------
$token = $env:TFE_TOKEN
if (-not $token) {
    $credFile = Join-Path $env:APPDATA "terraform.d\credentials.tfrc.json"
    if (-not (Test-Path $credFile)) { throw "No HCP token: run 'terraform login' or set TFE_TOKEN." }
    $token = (Get-Content $credFile -Raw | ConvertFrom-Json).credentials."app.terraform.io".token
}
$headers = @{ Authorization = "Bearer $token" }
$jsonApi = "application/vnd.api+json"

function Get-Run([string] $RunId) {
    (Invoke-RestMethod -Method Get -Uri "$api/runs/$RunId" -Headers $headers).data
}

# --- 1. Workspace ------------------------------------------------------------
$ws = (Invoke-RestMethod -Method Get -Headers $headers `
        -Uri "$api/organizations/$Organisation/workspaces/$Workspace").data
Write-Host "Workspace $Workspace ($($ws.id)), $($ws.attributes.'resource-count') resources in state"

if ($ws.attributes.'resource-count' -eq 0) {
    Write-Host "State is already empty: skipping destroy, running audit only."
} else {
    # --- 2. Queue destroy run --------------------------------------------------
    $body = @{
        data = @{
            type          = "runs"
            attributes    = @{ "is-destroy" = $true; message = "Cleanup via scripts/destroy.ps1" }
            relationships = @{ workspace = @{ data = @{ type = "workspaces"; id = $ws.id } } }
        }
    } | ConvertTo-Json -Depth 10

    $run = (Invoke-RestMethod -Method Post -Uri "$api/runs" -Headers $headers `
              -ContentType $jsonApi -Body $body).data
    $runUrl = "https://app.terraform.io/app/$Organisation/workspaces/$Workspace/runs/$($run.id)"
    Write-Host "Destroy run queued: $runUrl"

    # --- 3 + 4. Wait, confirm, wait ---------------------------------------------
    $deadline  = (Get-Date).AddMinutes($TimeoutMinutes)
    $confirmed = $false
    $final     = @("applied", "planned_and_finished", "errored", "discarded", "canceled", "force_canceled", "policy_soft_failed")

    while ($true) {
        if ((Get-Date) -gt $deadline) { throw "Timed out after $TimeoutMinutes minutes. Check $runUrl" }
        $run    = Get-Run $run.id
        $status = $run.attributes.status
        Write-Host "  status: $status"

        if ($final -contains $status) { break }

        if (-not $confirmed -and $run.attributes.actions.'is-confirmable') {
            Write-Host ""
            Write-Host "The destroy plan is ready and passed the policy check. Review it at:" -ForegroundColor Yellow
            Write-Host "  $runUrl" -ForegroundColor Yellow
            $answer = Read-Host "Type the workspace name '$Workspace' to destroy everything"
            if ($answer -ne $Workspace) {
                Invoke-RestMethod -Method Post -Uri "$api/runs/$($run.id)/actions/discard" -Headers $headers `
                    -ContentType $jsonApi -Body '{"comment":"Discarded by destroy.ps1 (not confirmed)"}' | Out-Null
                Write-Host "Not confirmed: destroy run discarded."
                exit 1
            }
            Invoke-RestMethod -Method Post -Uri "$api/runs/$($run.id)/actions/apply" -Headers $headers `
                -ContentType $jsonApi -Body '{"comment":"Confirmed via destroy.ps1"}' | Out-Null
            $confirmed = $true
        }
        Start-Sleep -Seconds 10
    }

    if ($status -ne "applied") { throw "Destroy run ended with status '$status'. Check $runUrl" }
    Write-Host "Destroy applied." -ForegroundColor Green
}

# --- 5. Audit -------------------------------------------------------------------
Write-Host ""
$auditArgs = @{}
if ($AwsProfile) { $auditArgs.Profile = $AwsProfile }
& (Join-Path $PSScriptRoot "audit-regions.ps1") @auditArgs
exit $LASTEXITCODE
