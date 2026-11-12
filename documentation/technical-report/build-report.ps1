<#
.SYNOPSIS
    Rebuilds technical-report.pdf from technical-report.md and checks that it is
    still ONE A4 page (the assignment limit).

.DESCRIPTION
    md2html.py converts the Markdown (headings, the table, lists, bold, code)
    into print-styled HTML; headless Chrome prints it to an A4 PDF; the script
    then counts the PDF pages and fails if there is more than one.

    Requires Python 3 and Google Chrome (or set -Browser to Edge's msedge.exe).

.EXAMPLE
    .\documentation\technical-report\build-report.ps1
#>
param(
    [string] $Browser = "C:\Program Files\Google\Chrome\Application\chrome.exe"
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$tmp  = Join-Path ([IO.Path]::GetTempPath()) ("atul-report-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Force $tmp | Out-Null
try {
    $html = Join-Path $tmp "report.html"
    $pdf  = Join-Path $here "technical-report.pdf"
    python (Join-Path $here "md2html.py") (Join-Path $here "technical-report.md") $html
    if ($LASTEXITCODE -ne 0) { throw "md2html.py failed" }
    if (Test-Path $pdf) { Remove-Item $pdf }
    & $Browser --headless=new --disable-gpu --no-pdf-header-footer "--user-data-dir=$tmp\profile" `
        "--print-to-pdf=$pdf" ("file:///" + ($html -replace '\\', '/')) 2>$null
    for ($i = 0; $i -lt 20 -and -not (Test-Path $pdf); $i++) { Start-Sleep -Milliseconds 500 }
    if (-not (Test-Path $pdf)) { throw "No PDF produced: check the -Browser path." }
    Start-Sleep -Seconds 1
    $raw   = [IO.File]::ReadAllText($pdf, [Text.Encoding]::GetEncoding(28591))
    $pages = ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count
    if ($pages -gt 1) {
        Write-Host "technical-report.pdf has $pages pages: shorten the Markdown to fit one page." -ForegroundColor Red
        exit 1
    }
    Write-Host "technical-report.pdf rebuilt: $pages page (A4)." -ForegroundColor Green
} finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
