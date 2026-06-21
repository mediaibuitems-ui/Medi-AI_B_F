param(
    [string]$projectPath = "Backend/Medi-AI_backend-main/Backend-APIs/Backend-APIs.csproj"
)

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Building $projectPath..."
dotnet build $projectPath --nologo
if ($LASTEXITCODE -eq 0) {
    $status = "Success"
} else {
    $status = "Failed"
}

$workspaceRoot = (Resolve-Path ".").Path
$todoPath = Join-Path $workspaceRoot "TODO_MANAGED.md"

$header = @"\
> Last status update: $ts
> Last build result: $status

"@

if (Test-Path $todoPath) {
    $content = Get-Content -Raw -Path $todoPath -ErrorAction SilentlyContinue
    $content = $content -replace '(> Last status update:.*\r?\n> Last build result:.*\r?\n\r?\n)', ''
    $new = $header + $content
    Set-Content -Path $todoPath -Value $new -Encoding UTF8
    Write-Host "Updated status in $todoPath"
} else {
    $template = "# TODO — Project Task List`n`n" + $header + "Core tasks`n`n- [ ] Run project error check`n- [ ] Create/standardize TODO.md`n- [ ] Add status updater script`n- [ ] Verify build and update statuses`n- [ ] Commit changes`n"
    New-Item -Path $todoPath -ItemType File -Force | Out-Null
    Set-Content -Path $todoPath -Value $template -Encoding UTF8
    Write-Host "Created $todoPath with status"
}
