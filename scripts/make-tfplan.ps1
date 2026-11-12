<#
.SYNOPSIS
    Produces terraform/tfplan (binary saved plan) and terraform/tfplan.txt
    (readable output) for the assignment deliverable.

.DESCRIPTION
    The real plans for this project run in HCP Terraform (the cloud block), so
    `terraform plan -out` in terraform/ would not produce a normal plan file.
    This script plans the SAME code locally instead:

      1. copies terraform/*.tf, the lock file and the already-downloaded
         .terraform/ folder (providers + modules) into a temporary directory
      2. adds an override file there that swaps the cloud block for a local
         backend with an EMPTY state (Terraform override files replace a
         cloud/backend block), so nothing in terraform/ or HCP is touched
      3. runs `terraform plan -out=tfplan` with the given AWS profile (read-only:
         it only reads the AMI SSM parameter) and `terraform show` for the text
      4. copies tfplan and tfplan.txt back into terraform/ and removes the
         temporary directory

    Because the state is empty, the plan shows the full compliant stack being
    created (the same 23 resources as the first HCP run) and contains no data
    from the running infrastructure (no account ID in ARNs, no IP addresses).

.EXAMPLE
    .\scripts\make-tfplan.ps1 -AwsProfile atu
#>
param(
    [string] $AwsProfile
)

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$tf   = Join-Path $repo "terraform"
$tmp  = Join-Path ([IO.Path]::GetTempPath()) ("atul-tfplan-" + [guid]::NewGuid().ToString("N").Substring(0, 8))

if (-not (Test-Path (Join-Path $tf ".terraform"))) {
    throw "terraform/.terraform not found: run 'terraform init' in terraform/ once first."
}
if ($AwsProfile) { $env:AWS_PROFILE = $AwsProfile }

New-Item -ItemType Directory -Force $tmp | Out-Null
try {
    Copy-Item (Join-Path $tf "*.tf"), (Join-Path $tf ".terraform.lock.hcl") $tmp
    Copy-Item (Join-Path $tf ".terraform") (Join-Path $tmp ".terraform") -Recurse
    # Old backend settings point at HCP; the override + -reconfigure replace them.
    Remove-Item (Join-Path $tmp ".terraform\terraform.tfstate") -ErrorAction SilentlyContinue
    Set-Content (Join-Path $tmp "zz_local_backend_override.tf") -Encoding ascii -Value @'
# Temporary override (make-tfplan.ps1): replace the HCP cloud block with an
# empty local state, so the plan shows the full stack and no live data.
terraform {
  backend "local" {
    path = "empty.tfstate"
  }
}
'@

    Push-Location $tmp
    try {
        terraform init -reconfigure -input=false -no-color | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "terraform init failed in the temporary copy." }
        terraform plan -input=false -no-color -out=tfplan | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "terraform plan failed." }
        terraform show -no-color tfplan | Out-File -Encoding utf8 tfplan.txt
    } finally { Pop-Location }

    Copy-Item (Join-Path $tmp "tfplan"), (Join-Path $tmp "tfplan.txt") $tf -Force
    $summary = Select-String -Path (Join-Path $tf "tfplan.txt") -Pattern "^Plan:" | Select-Object -Last 1
    Write-Host "Written terraform/tfplan and terraform/tfplan.txt" -ForegroundColor Green
    Write-Host "  $($summary.Line)"
} finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
