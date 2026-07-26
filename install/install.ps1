#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $PSScriptRoot

# On demande à pandoc lui-même son data dir
$versionOutput = & pandoc --version 2>$null
$line = $versionOutput | Select-String -Pattern "data directory" | Select-Object -First 1

if ($line) {
    $DataDir = ($line.ToString() -replace '^[^:]+:\s*', '') -replace '\s+or\s+.*$', ''
} else {
    $DataDir = Join-Path $env:APPDATA "pandoc"
    Write-Warning "pandoc introuvable ou sortie inattendue, repli sur : $DataDir"
}

Write-Host "Depot    : $RepoDir"
Write-Host "Data dir : $DataDir"
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

foreach ($sub in "reference-docs", "filters", "defaults") {
    $target = Join-Path $DataDir $sub
    $source = Join-Path $RepoDir $sub

    if (Test-Path $target) {
        $item = Get-Item $target -Force
        if ($item.LinkType) {
            Remove-Item $target -Force
        } else {
            $backup = "$target.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Write-Warning "$target existe deja (pas un lien) -> sauvegarde en $backup"
            Rename-Item $target $backup
        }
    }

    New-Item -ItemType Junction -Path $target -Target $source | Out-Null
    Write-Host "  OK : $sub -> $source"
}

Write-Host ""
Write-Host "Test : pandoc -d bts-sio -o test.docx source.md"
