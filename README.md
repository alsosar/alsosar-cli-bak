 ```
░█████╗░██╗░░░░░██╗░░░░░░██████╗░░█████╗░██╗░░██╗
██╔══██╗██║░░░░░██║░░░░░░██╔══██╗██╔══██╗██║░██╔╝
██║░░╚═╝██║░░░░░██║█████╗██████╦╝███████║█████═╝░
██║░░██╗██║░░░░░██║╚════╝██╔══██╗██╔══██║██╔═██╗░
╚█████╔╝███████╗██║░░░░░░██████╦╝██║░░██║██║░╚██╗
░╚════╝░╚══════╝╚═╝░░░░░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝
 ```

# alsosar-cli-bak

Windows user data backup tool with automatic OneDrive path detection.

## Usage

Choose Local or OneDrive+Local, then enter your destination:

From **CMD** or **PowerShell** with flags (non-interactive):

```
backup C:\BackupFolder
```

**Backup from local paths only:**

```
backup C:\BackupFolder -Local
```

Or double-click `backup.bat` in Explorer.

### Run Directly From GitHub (no download required)

From **PowerShell 5+** (run as administrator if backing up system folders):

Master Powershell Command
# Interactive mode (choose Local or OneDrive+Local, then enter destination)
```
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/alsosar/alsosar-cli-bak/master/backup.ps1)))
```

# Local paths only
```
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/alsosar/alsosar-cli-bak/master/backup.ps1))) -Destination D:\Backup -Local
```

This downloads the script into memory and runs it immediately — no file saved to disk.

## Flags

| Flag     | Description                                              |
|----------|----------------------------------------------------------|
| `-Local` | Backup `C:\Users\%USERNAME%\Desktop` only (skip OneDrive) |

## How it works

By default, for each folder (Desktop, Documents, etc.) the tool detects **all available source locations**:

| Folder     | OneDrive path (if active)    | Local path                    |
|------------|------------------------------|-------------------------------|
| Desktop    | `%USERPROFILE%\OneDrive\Desktop` | `%USERPROFILE%\Desktop`    |
| Documents  | `%USERPROFILE%\OneDrive\Documents` | `%USERPROFILE%\Documents` |
| Downloads  | (via registry)               | `%USERPROFILE%\Downloads`     |
| Pictures   | `%USERPROFILE%\OneDrive\Pictures` | `%USERPROFILE%\Pictures`   |
| Music      | (via registry)               | `%USERPROFILE%\Music`         |
| Videos     | (via registry)               | `%USERPROFILE%\Videos`        |

If both OneDrive and local paths exist for the same folder (e.g. files in both
`OneDrive\Desktop` and `\Desktop`), **both** are backed up. The local copy
appears as `Desktop (local)` in the destination.

Use `-Local` to skip OneDrive and backup only from `%USERPROFILE%` paths.

Uses `robocopy` (built into Windows) for reliable copying with retries.

All output is wrapped in a decorative frame using `Write-Frame` (available as a reusable function in the script).
