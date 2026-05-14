param(
    [Parameter(Position = 0)]
    [string]$Destination,

    [switch]$WhatIf
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

$folderDefs = @(
    @{ Name = 'Desktop';   Path = [Environment]::GetFolderPath('Desktop') }
    @{ Name = 'Documents'; Path = [Environment]::GetFolderPath('MyDocuments') }
    @{ Name = 'Downloads'; Path = Get-DownloadsPath }
    @{ Name = 'Pictures';  Path = [Environment]::GetFolderPath('MyPictures') }
    @{ Name = 'Music';     Path = [Environment]::GetFolderPath('MyMusic') }
    @{ Name = 'Videos';    Path = [Environment]::GetFolderPath('MyVideos') }
)

$sourceFolders = @()
foreach ($f in $folderDefs) {
    if ($f.Path -and (Test-Path -LiteralPath $f.Path -PathType Container)) {
        $sourceFolders += $f
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
if ($WhatIf) { Write-Host "  Mode:    WHAT-IF (preview only)" -ForegroundColor Yellow }
Write-Host "Env: PowerShell $($PSVersionTable.PSVersion)" | Out-File -FilePath $logFile
"asosar-winbak v1.0 - Windows User Backup" | Out-File -FilePath $logFile
"Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $logFile -Append
"User:    $([Environment]::UserName)" | Out-File -FilePath $logFile -Append
"Target:  $destPath" | Out-File -FilePath $logFile -Append
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
Write-Host "  Folders:  $($sourceFolders.Count) of $($folderDefs.Count)"
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
