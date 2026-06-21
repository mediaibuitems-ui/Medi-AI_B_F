param(
    [Parameter(Mandatory=$false)]
    [string[]]$Paths
)

$root = (Resolve-Path ".").Path
$archiveRoot = Join-Path $root "archive"
if (-not (Test-Path $archiveRoot)) { New-Item -Path $archiveRoot -ItemType Directory | Out-Null }

if (-not $Paths -or $Paths.Count -eq 0) {
    Write-Host "No paths provided. Pass file or folder paths to move to archive. Example:`n./scripts/archive_files.ps1 -Paths 'Backend/Medi-AI_backend-main' 'build'"
    exit 0
}

foreach ($p in $Paths) {
    $full = Join-Path $root $p
    if (-not (Test-Path $full)) {
        Write-Warning "Path not found: $p"
        continue
    }
    $dest = Join-Path $archiveRoot ((Split-Path $p -Leaf))
    if (Test-Path $dest) {
        $stamp = Get-Date -Format yyyyMMddHHmmss
        $dest = "$dest-$stamp"
    }
    Write-Host "Archiving $p -> $dest"
    Move-Item -Path $full -Destination $dest -Force
}

Write-Host "Archive complete. See $archiveRoot"
