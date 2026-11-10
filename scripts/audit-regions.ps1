<#
.SYNOPSIS
    Lists what exists in AWS for this project and flags anything outside the
    approved EU regions as sovereignty DRIFT.

.DESCRIPTION
    Sentinel only checks Terraform plans. Anything created outside Terraform
    (console, CLI, another tool) is invisible to it. This script is the
    after-the-fact control: it inspects the real account.

    Approved regions (eu-west-1, eu-central-1):
        project resources still present are reported as LEFTOVER
        (expected while the stack is deployed, a cleanup failure after destroy)
    Any other checked region (default: us-east-1):
        ANY snapshot, volume or running instance owned by the account is
        reported as DRIFT, tagged or not, because a manual copy does not
        carry the project tags.

    Exit code: 0 = clean, 1 = leftovers and/or drift found.

.EXAMPLE
    .\scripts\audit-regions.ps1
    .\scripts\audit-regions.ps1 -Profile admin -OffRegions us-east-1,us-west-2
#>
param(
    [string]   $Profile,
    [string[]] $ApprovedRegions = @("eu-west-1", "eu-central-1"),
    [string[]] $OffRegions      = @("us-east-1"),
    [string]   $Organisation    = "ATUL0012345"
)

$ErrorActionPreference = "Stop"
$found = 0

function Invoke-Aws {
    param([string] $Region, [string[]] $Arguments)
    $cmd = @($Arguments) + @("--region", $Region, "--output", "json")
    if ($Profile) { $cmd += @("--profile", $Profile) }
    $raw = & aws @cmd
    if ($LASTEXITCODE -ne 0) { throw "aws $($Arguments -join ' ') failed in $Region" }
    return ($raw -join "`n") | ConvertFrom-Json
}

function Report {
    param([string] $Status, [string] $Region, [string] $Kind, [string] $Id, [string] $Detail)
    $colour = if ($Status -eq "DRIFT") { "Red" } else { "Yellow" }
    Write-Host ("  [{0,-8}] {1,-13} {2,-10} {3,-24} {4}" -f $Status, $Region, $Kind, $Id, $Detail) -ForegroundColor $colour
    $script:found++
}

$identity = Invoke-Aws -Region "eu-west-1" -Arguments @("sts", "get-caller-identity")
Write-Host "Account $($identity.Account) as $($identity.Arn)"
Write-Host ""

$tagFilter = "Name=tag:Organisation,Values=$Organisation"

foreach ($region in $ApprovedRegions) {
    Write-Host "Approved region $region (project resources tagged Organisation=$Organisation):"

    $instances = Invoke-Aws $region @("ec2", "describe-instances", "--filters", $tagFilter,
        "Name=instance-state-name,Values=pending,running,stopping,stopped")
    foreach ($i in $instances.Reservations.Instances) { Report "LEFTOVER" $region "instance" $i.InstanceId $i.State.Name }

    $volumes = Invoke-Aws $region @("ec2", "describe-volumes", "--filters", $tagFilter)
    foreach ($v in $volumes.Volumes) { Report "LEFTOVER" $region "volume" $v.VolumeId "$($v.Size) GiB, encrypted=$($v.Encrypted)" }

    $snaps = Invoke-Aws $region @("ec2", "describe-snapshots", "--owner-ids", "self", "--filters", $tagFilter)
    foreach ($s in $snaps.Snapshots) { Report "LEFTOVER" $region "snapshot" $s.SnapshotId "encrypted=$($s.Encrypted)" }

    $vpcs = Invoke-Aws $region @("ec2", "describe-vpcs", "--filters", $tagFilter)
    foreach ($v in $vpcs.Vpcs) { Report "LEFTOVER" $region "vpc" $v.VpcId $v.CidrBlock }

    # KMS keys cannot be deleted instantly: after destroy they sit in
    # PendingDeletion for 7 days, which is expected and not counted.
    $aliases = Invoke-Aws $region @("kms", "list-aliases")
    foreach ($a in $aliases.Aliases | Where-Object { $_.AliasName -like "alias/$($Organisation.ToLower())-*" }) {
        Report "LEFTOVER" $region "kms-alias" $a.AliasName $a.TargetKeyId
    }
    Write-Host ""
}

foreach ($region in $OffRegions) {
    Write-Host "Off-region $region (ANY owned resource is sovereignty drift):"

    $snaps = Invoke-Aws $region @("ec2", "describe-snapshots", "--owner-ids", "self")
    foreach ($s in $snaps.Snapshots) { Report "DRIFT" $region "snapshot" $s.SnapshotId "copied from: $($s.Description)" }

    $volumes = Invoke-Aws $region @("ec2", "describe-volumes")
    foreach ($v in $volumes.Volumes) { Report "DRIFT" $region "volume" $v.VolumeId "$($v.Size) GiB" }

    $instances = Invoke-Aws $region @("ec2", "describe-instances",
        "--filters", "Name=instance-state-name,Values=pending,running,stopping,stopped")
    foreach ($i in $instances.Reservations.Instances) { Report "DRIFT" $region "instance" $i.InstanceId $i.State.Name }
    Write-Host ""
}

if ($found -eq 0) {
    Write-Host "CLEAN: nothing found outside expectations." -ForegroundColor Green
    exit 0
}
Write-Host "$found item(s) found. LEFTOVER = still deployed or not cleaned up, DRIFT = data outside approved EU regions." -ForegroundColor Red
exit 1
