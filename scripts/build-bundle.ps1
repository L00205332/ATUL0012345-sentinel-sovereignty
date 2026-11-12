<#
.SYNOPSIS
    Builds the single mandatory policy that HCP Terraform Free allows, from the
    separate policy files in sentinel/, and tests it.

.DESCRIPTION
    HCP Terraform Free allows only ONE mandatory (hard or soft) policy per
    organisation. The repo keeps one policy file per control area (matching the
    assignment structure, each tested on its own). This script merges every
    policy marked hard-mandatory or soft-mandatory in sentinel.hcl into one
    hard-mandatory policy, so all of them still block a non-compliant run.

      1. reads the policy list and enforcement levels from sentinel.hcl
      2. for each mandatory policy: takes its imports, its body (everything
         before its `main` rule) and the names of its rules
      3. fails if two policies define the same top-level name
      4. writes sentinel/build/<bundle>.sentinel with ONE main = all rules
      5. generates bundle test cases from each policy's own tests and runs them:
           - fail tests keep their expectations (the bundle must reject them
             for the same reasons)
           - pass tests check that policy's own rules are all true
           - pass-real* tests (real HCP plans) must pass the WHOLE bundle

    Each policy file must therefore be "bundle-ready": imports at the top, a
    final `main = rule { ... }` block, and unique top-level names.

    Returns an object describing what to deploy (used by upload-policies.ps1).

.EXAMPLE
    .\scripts\build-bundle.ps1
#>
param(
    [string] $BundleName = "atul0012345-guardrails"
)

$ErrorActionPreference = "Stop"
$sentinel  = Join-Path (Split-Path $PSScriptRoot -Parent) "sentinel"
$buildDir  = Join-Path $sentinel "build"
$fileStem  = $BundleName -replace '-', '_'
$bundleSrc = Join-Path $buildDir "$fileStem.sentinel"
$testDir   = Join-Path $buildDir "test/$fileStem"   # forward slashes work on Windows and Linux (CI)

# --- 1. Policies from sentinel.hcl ------------------------------------------------
$hcl = Get-Content (Join-Path $sentinel "sentinel.hcl") -Raw
$hcl = ($hcl -split "`n" | ForEach-Object { $_ -replace '#.*$', '' }) -join "`n"
$policies = foreach ($b in [regex]::Matches($hcl, 'policy\s+"(?<name>[^"]+)"\s*\{(?<body>[^}]*)\}')) {
    $body   = $b.Groups["body"].Value
    $source = [regex]::Match($body, 'source\s*=\s*"(?<v>[^"]+)"').Groups["v"].Value
    $level  = [regex]::Match($body, 'enforcement_level\s*=\s*"(?<v>[^"]+)"').Groups["v"].Value
    if (-not $level) { $level = "advisory" }
    $path = Join-Path $sentinel ($source -replace '^\./', '')
    if (-not (Test-Path $path)) { throw "Policy source not found: $path" }
    [pscustomobject]@{ Name = $b.Groups["name"].Value; Path = $path; Level = $level }
}
$mandatory = @($policies | Where-Object { $_.Level -ne "advisory" })
$advisory  = @($policies | Where-Object { $_.Level -eq "advisory" })
if ($mandatory.Count -eq 0) { throw "No mandatory policies in sentinel.hcl: nothing to bundle." }

# --- 2 + 3. Split each policy into imports / body / rules ------------------------------
$imports  = [System.Collections.Generic.List[string]]::new()
$params   = [System.Collections.Generic.List[string]]::new()   # Sentinel requires params before any statement
$sections = [System.Collections.Generic.List[string]]::new()
$allRules = [System.Collections.Generic.List[string]]::new()
$owner    = @{}   # top-level name -> policy that defines it
$rulesOf  = @{}   # policy name -> its rule names

foreach ($p in $mandatory) {
    $lines = Get-Content $p.Path
    $mainAt = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^main\s*=\s*rule\s*\{') { $mainAt = $i } }
    if ($mainAt -lt 0) { throw "$($p.Name): no top-level 'main = rule {' found." }

    # The comment block directly above main belongs to main: drop it too.
    $cut = $mainAt
    while ($cut -gt 0 -and $lines[$cut - 1] -match '^\s*#') { $cut-- }

    $body = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $cut; $i++) {
        $line = $lines[$i]
        if ($line -match '^import\s+"') {
            if (-not $imports.Contains($line.Trim())) { $imports.Add($line.Trim()) }
            continue
        }
        if ($line -match '^param\s+(?<n>[A-Za-z_][A-Za-z0-9_]*)') {
            $n = $Matches["n"]
            if ($owner.ContainsKey($n) -and $owner[$n] -ne $p.Name) {
                throw "Name clash: param '$n' is defined in both $($owner[$n]) and $($p.Name)."
            }
            $owner[$n] = $p.Name
            # A param can span several lines (e.g. a list default): take lines
            # until the brackets balance again.
            $block = [System.Collections.Generic.List[string]]::new()
            $depth = 0
            do {
                $l = $lines[$i]
                $block.Add($l)
                $depth += ([regex]::Matches($l, '[\[\{]').Count - [regex]::Matches($l, '[\]\}]').Count)
                $i++
            } while ($depth -gt 0 -and $i -lt $cut)
            $i--
            $params.Add("# from $(Split-Path $p.Path -Leaf)`n" + ($block -join "`n"))
            continue
        }
        if ($line -match '^(param\s+)?(?<n>[A-Za-z_][A-Za-z0-9_]*)\s*(=|default)') {
            $n = $Matches["n"]
            if ($owner.ContainsKey($n) -and $owner[$n] -ne $p.Name) {
                throw "Name clash: '$n' is defined in both $($owner[$n]) and $($p.Name). Rename one of them."
            }
            $owner[$n] = $p.Name
        }
        $body.Add($line)
    }

    $rules = @(for ($i = 0; $i -lt $cut; $i++) {
        if ($lines[$i] -match '^(?<n>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*rule\b') { $Matches["n"] }
    })
    if ($rules.Count -eq 0) { throw "$($p.Name): no rules found besides main." }
    $rulesOf[$p.Name] = $rules
    $rules | ForEach-Object { $allRules.Add($_) }

    $sections.Add("# =============================================================================`n" +
                  "# From $(Split-Path $p.Path -Leaf) (rules: $($rules -join ', '))`n" +
                  "# =============================================================================`n" +
                  (($body -join "`n").Trim()))
}

# Indented assignments inside top-level for loops are top-level variables too
# (Sentinel loops have no scope of their own), so they must not reuse a name
# that another bundled policy defines at the top level.
foreach ($p in $mandatory) {
    foreach ($line in Get-Content $p.Path) {
        if ($line -match '^\s+(?<n>[A-Za-z_][A-Za-z0-9_]*)\s*=[^=]') {
            $n = $Matches["n"]
            if ($owner.ContainsKey($n) -and $owner[$n] -ne $p.Name) {
                throw "Name clash: $($p.Name) assigns '$n', which $($owner[$n]) defines at the top level. Rename it in $($p.Name)."
            }
        }
    }
}

# --- 4. Write the bundle ----------------------------------------------------------------
if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
New-Item -ItemType Directory -Force $testDir | Out-Null

$header = @"
# $BundleName
#
# GENERATED by scripts/build-bundle.ps1. Do not edit: change the policy files in
# sentinel/ and rebuild. HCP Terraform Free allows a single mandatory policy, so
# every mandatory policy from sentinel.hcl is merged here and enforced as ONE
# hard-mandatory policy. Each FAIL line still names the original rule.
#
# Bundled: $(($mandatory | ForEach-Object { Split-Path $_.Path -Leaf }) -join ', ')
"@

$main = "# Every rule from every bundled policy is evaluated, so the output lists all`n" +
        "# violations at once.`n" +
        "main = rule {`n`tall [`n" + (($allRules | ForEach-Object { "`t`t$_,`n" }) -join '') + "`t] as r {`n`t`tr`n`t}`n}"

$bundle = $header + "`n`n" + ($imports -join "`n") + "`n`n" + ($params -join "`n`n") + "`n`n" +
          ($sections -join "`n`n") + "`n`n" + $main + "`n"
[IO.File]::WriteAllText($bundleSrc, $bundle, (New-Object System.Text.UTF8Encoding $false))

# --- 5. Bundle tests ---------------------------------------------------------------------
# The bundle imports what ALL its policies import. A test written for one policy
# may not mock every one of them (e.g. network tests have no tfconfig/v2 mock),
# so an empty mock is added for any missing Terraform import.
$emptyMocks = @{
    "tfplan/v2"   = "resource_changes = {}`n`nresource_drift = {}`n`noutput_changes = {}`n`nvariables = {}"
    "tfconfig/v2" = "resources = {}`n`nproviders = {}`n`nmodule_calls = {}`n`nvariables = {}`n`noutputs = {}"
    "tfstate/v2"  = "resources = {}`n`noutputs = {}"
    "tfrun"       = "workspace = {}`n`norganization = {}"
}
$needed = @($imports | ForEach-Object { [regex]::Match($_, '^import\s+"(?<i>[^"]+)"').Groups["i"].Value } |
            Where-Object { $emptyMocks.ContainsKey($_) })
foreach ($i in $needed) {
    $file = "mock-empty-" + ($i -replace '/', '-') + ".sentinel"
    [IO.File]::WriteAllText((Join-Path $testDir $file), "# Empty mock for $i (test did not mock it)`n" + $emptyMocks[$i] + "`n",
        (New-Object System.Text.UTF8Encoding $false))
}

foreach ($p in $mandatory) {
    $srcTests = Join-Path $sentinel "test/$($p.Name)"
    if (-not (Test-Path $srcTests)) { throw "$($p.Name) has no tests in test/$($p.Name): it cannot be bundled untested." }
    foreach ($t in Get-ChildItem $srcTests -Filter *.hcl) {
        $text = Get-Content $t.FullName -Raw
        # Mock paths are relative to the test file: point them back at the original folder.
        $text = [regex]::Replace($text, 'source\s*=\s*"(?<s>[^"]+)"', {
            param($m) 'source = "../../../test/' + $p.Name + '/' + $m.Groups["s"].Value + '"'
        })
        $rulesBlock = [regex]::Match($text, 'rules\s*=\s*\{(?<r>[^}]*)\}').Groups["r"].Value
        $expected = [ordered]@{}
        foreach ($m in [regex]::Matches($rulesBlock, '(?<k>\w+)\s*=\s*(?<v>true|false)')) { $expected[$m.Groups["k"].Value] = $m.Groups["v"].Value }

        if ($expected["main"] -eq "true" -and $t.BaseName -notlike "pass-real*") {
            # Synthetic pass mock: only this policy's rules must hold.
            $expected = [ordered]@{}
            $rulesOf[$p.Name] | ForEach-Object { $expected[$_] = "true" }
        }
        $newRules = "rules = {`n" + (($expected.Keys | ForEach-Object { "    $_ = $($expected[$_])" }) -join "`n") + "`n  }"
        $text = [regex]::Replace($text, 'rules\s*=\s*\{[^}]*\}', $newRules)
        foreach ($i in $needed) {
            if ($text -notmatch ('mock\s+"' + [regex]::Escape($i) + '"')) {
                $file = "mock-empty-" + ($i -replace '/', '-') + ".sentinel"
                $text = "mock `"$i`" {`n  module {`n    source = `"$file`"`n  }`n}`n`n" + $text
            }
        }
        $text = "# Generated from test/$($p.Name)/$($t.Name)`n" + $text
        [IO.File]::WriteAllText((Join-Path $testDir "$($p.Name)-$($t.Name)"), $text, (New-Object System.Text.UTF8Encoding $false))
    }
}

Push-Location $buildDir
try {
    sentinel fmt "$fileStem.sentinel" | Out-Null
    $out = sentinel test 2>&1
    $code = $LASTEXITCODE
    $out | Where-Object { $_ -match '^\s*(PASS|FAIL|ERROR)' } | ForEach-Object { Write-Host "  $_" }
    if ($code -ne 0) {
        $out | ForEach-Object { Write-Host $_ }
        throw "Bundle tests failed: the merged policy does not behave like its parts."
    }
} finally { Pop-Location }

Write-Host "Built $BundleName from: $(($mandatory | ForEach-Object { $_.Name }) -join ', ') ($($allRules.Count) rules)" -ForegroundColor Green

[pscustomobject]@{
    BundleName = $BundleName
    BundlePath = $bundleSrc
    Bundled    = @($mandatory | ForEach-Object { $_.Name })
    Advisory   = $advisory
}
