# asosar-winbak

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

**Force local paths** (skip OneDrive):

```
backup D:\BackupFolder -Local
```

Or double-click `backup.bat` in Explorer.

## Flags

| Flag     | Description                                          |
|----------|------------------------------------------------------|
| `-Local` | Use `C:\Users\%USERNAME%\Desktop` instead of OneDrive paths |
| `-WhatIf`| Preview what would be backed up without copying      |

## What it backs up

| Folder     | Default (OneDrive-aware)        | With `-Local`                   |
|------------|---------------------------------|---------------------------------|
| Desktop    | OneDrive\Desktop                | %USERPROFILE%\Desktop           |
| Documents  | OneDrive\Documents              | %USERPROFILE%\Documents         |
| Downloads  | Registry or %USERPROFILE%\Downloads | %USERPROFILE%\Downloads     |
| Pictures   | OneDrive\Pictures               | %USERPROFILE%\Pictures          |
| Music      | OneDrive\Music                  | %USERPROFILE%\Music             |
| Videos     | OneDrive\Videos                 | %USERPROFILE%\Videos            |

Uses `robocopy` (built into Windows) for reliable copying with retries.
