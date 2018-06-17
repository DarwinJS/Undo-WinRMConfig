
## 

### Find Out What Your OS Version Is:

Run this code to emit the version string that Undo-WinRMConfig will use:

```
If ($psversiontable.psversion.major -lt 3)
{ Write-Host "OS Version String: $((Get-WMIObject Win32_OperatingSystem).version)" }
Else 
{  Write-Host "OS Version String: $((Get-CIMInstance Win32_OperatingSystem).version)" }
```

Check here: whether a profile has already been done for that version.

System Explorer install via chocolatey
Editing .REG
