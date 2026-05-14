param(
    [Parameter(Position = 0)]
    [string]$Destination,

    [switch]$WhatIf,

    [switch]$Local
)

$ErrorActionPreference = 'Continue'
$startTime = Get-Date
$totalFailed = 0

function Get-UserShellFolder {
    param([string]$Key)
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    try {
        $val = Get-ItemProperty -Path $regPath -Name $Key -ErrorAction Stop
        return [Environment]::ExpandEnvironmentVariables($val.$Key)
    } catch {
        return $null
    }
}

function Get-DownloadsPath {
    $path = Get-UserShellFolder -Key '{374DE290-123F-4565-9164-39C4925E467B}'
    if (-not $path) { $path = Join-Path $HOME 'Downloads' }
    return $path
}

function Get-ActivePath {
    param([string]$Folder)
    switch ($Folder) {
        'Desktop'   { return [Environment]::GetFolderPath('Desktop') }
        'Documents' { return [Environment]::GetFolderPath('MyDocuments') }
        'Downloads' { return Get-DownloadsPath }
        'Pictures'  { return [Environment]::GetFolderPath('MyPictures') }
        'Music'     { return [Environment]::GetFolderPath('MyMusic') }
        'Videos'    { return [Environment]::GetFolderPath('MyVideos') }
    }
}

$folderNames = @('Desktop', 'Documents', 'Downloads', 'Pictures', 'Music', 'Videos')
$sourceFolders = @()

if ($Local) {
    foreach ($folderName in $folderNames) {
        $folderPath = "$HOME\$folderName"
        if (Test-Path -LiteralPath $folderPath -PathType Container) {
            $sourceFolders += @{ Name = $folderName; Path = $folderPath }
        }
    }
} else {
    foreach ($folderName in $folderNames) {
        $active = Get-ActivePath $folderName
        $localPath = "$HOME\$folderName"
        $seen   = @{}

        if ($active -and (Test-Path -LiteralPath $active -PathType Container)) {
            $sourceFolders += @{ Name = $folderName; Path = $active }
            $seen[$active.ToLower()] = $true
        }
        if ($localPath -and (Test-Path -LiteralPath $localPath -PathType Container) -and -not $seen[$localPath.ToLower()]) {
            $label = if ($active -and $active -ne $localPath) { ' (local)' } else { '' }
            $sourceFolders += @{ Name = "$folderName$label"; Path = $localPath }
        }
    }
}

if ($sourceFolders.Count -eq 0) {
    Write-Host "No user folders found to backup." -ForegroundColor Red
    exit 1
}

if (-not $Destination) {
    do {
        $Destination = Read-Host "Enter backup destination folder path"
        $Destination = $Destination.Trim()
    } while (-not $Destination)
}

$destPath = [Environment]::ExpandEnvironmentVariables($Destination)
$destPath = $destPath -replace '"', ''
$destPath = $destPath.TrimEnd('\')

if (-not (Test-Path -LiteralPath $destPath)) {
    New-Item -ItemType Directory -Path $destPath -Force -ErrorAction Stop | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logFile = Join-Path $destPath "backup-$timestamp.log"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  asosar-winbak - Windows User Backup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "  User:    $([Environment]::UserName)"
Write-Host "  Target:  $destPath"
$modeLabel = if ($Local) { 'Local only' } else { 'OneDrive + Local (all sources)' }
Write-Host "  Mode:    $modeLabel"
if ($WhatIf) { Write-Host "  WHAT-IF: preview only (no files copied)" -ForegroundColor Yellow }
"asosar-winbak v1.1 - Windows User Backup" | Out-File -FilePath $logFile
"Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $logFile -Append
"User:    $([Environment]::UserName)" | Out-File -FilePath $logFile -Append
"Target:  $destPath" | Out-File -FilePath $logFile -Append
"Mode:    $modeLabel" | Out-File -FilePath $logFile -Append
"-" * 60 | Out-File -FilePath $logFile -Append

$i = 0
foreach ($folder in $sourceFolders) {
    $i++
    $src = $folder.Path
    $folderDest = Join-Path $destPath $folder.Name

    if ($WhatIf) {
        Write-Host "[$i/$($sourceFolders.Count)] $($folder.Name): $src -> $folderDest" -ForegroundColor Gray
        continue
    }

    Write-Host "[$i/$($sourceFolders.Count)] $($folder.Name)..." -ForegroundColor Yellow -NoNewline

    if (-not (Test-Path -LiteralPath $folderDest)) {
        New-Item -ItemType Directory -Path $folderDest -Force | Out-Null
    }

    "--- $($folder.Name) ---" | Out-File -FilePath $logFile -Append
    "Source: $src" | Out-File -FilePath $logFile -Append
    "Dest:   $folderDest" | Out-File -FilePath $logFile -Append

    & robocopy $src $folderDest /E /COPY:DAT /R:3 /W:3 /NDL /NFL /NP /LOG+:$logFile

    $exitCode = $LASTEXITCODE

    if ($exitCode -ge 8) {
        Write-Host " ERRORS ($exitCode)" -ForegroundColor Red
        $totalFailed++
    } elseif ($exitCode -eq 0) {
        Write-Host " up-to-date" -ForegroundColor Green
    } else {
        Write-Host " OK" -ForegroundColor Green
    }

    "" | Out-File -FilePath $logFile -Append
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Backup Complete!" -ForegroundColor Cyan
$endTime = Get-Date
$duration = $endTime - $startTime
$durationStr = "{0:hh}h {0:mm}m {0:ss}s" -f $duration
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Duration: $durationStr"
Write-Host "  Folders:  $($sourceFolders.Count)"
if ($totalFailed -gt 0) {
    Write-Host "  Errors:   $totalFailed folder(s)" -ForegroundColor Red
} else {
    Write-Host "  Errors:   None" -ForegroundColor Green
}
Write-Host "  Log:      $logFile"
Write-Host "========================================"

"" | Out-File -FilePath $logFile -Append
"-" * 60 | Out-File -FilePath $logFile -Append
"Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $logFile -Append
"Duration:  $durationStr" | Out-File -FilePath $logFile -Append
"Folders:   $($sourceFolders.Count) processed, $totalFailed errors" | Out-File -FilePath $logFile -Append

if ($totalFailed -gt 0) { exit 1 }
