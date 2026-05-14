# asosar-winbak

Windows user data backup tool. Automatically detects OneDrive paths.

## Usage

From **CMD** or **PowerShell**:

```
backup D:\MyBackup
```

Or run without arguments to be prompted:

```
backup
```

Or double-click `backup.bat` in Explorer.

## What it backs up

| Folder     | Path resolution                         |
|------------|-----------------------------------------|
| Desktop    | OneDrive\Desktop or %USERPROFILE%\Desktop |
| Documents  | OneDrive\Documents or %USERPROFILE%\Documents |
| Downloads  | Registry known folder or %USERPROFILE%\Downloads |
| Pictures   | OneDrive\Pictures or %USERPROFILE%\Pictures |
| Music      | OneDrive\Music or %USERPROFILE%\Music |
| Videos     | OneDrive\Videos or %USERPROFILE%\Videos |

Uses `robocopy` (built into Windows) for reliable copying with retries.
