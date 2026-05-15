#   
    _    ____   ___  ____    _    ____        ____ _     ___      ____    _    _  __
   / \  / ___| / _ \/ ___|  / \  |  _ \      / ___| |   |_ _|    | __ )  / \  | |/ /
  / _ \ \___ \| | | \___ \ / _ \ | |_) |____| |   | |    | |_____|  _ \ / _ \ | ' /
 / ___ \ ___) | |_| |___) / ___ \|  _ <_____| |___| |___ | |_____| |_) / ___ \| . \
/_/   \_\____/ \___/|____/_/   \_\_| \_\     \____|_____|___|    |____/_/   \_\_|\_\

                        Windows User Backup Tool

Windows user data backup tool with automatic OneDrive path detection.

## Usage

From **CMD** or **PowerShell**:

```
backup D:\BackupFolder
```

Run without arguments to be prompted for a destination:

```
backup
```

**Backup from local paths only:**

```
backup D:\BackupFolder -Local
```

Or double-click `backup.bat` in Explorer.

## Flags

| Flag     | Description                                              |
|----------|----------------------------------------------------------|
| `-Local` | Backup `C:\Users\%USERNAME%\Desktop` only (skip OneDrive) |
| `-WhatIf`| Preview what would be backed up without copying          |

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
