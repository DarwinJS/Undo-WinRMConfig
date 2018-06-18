
## 

### Find Out What Your OS Version Is:

Run this code to emit the version string that Undo-WinRMConfig will use:

```
If ($psversiontable.psversion.major -lt 3)
{ Write-Host "OS Version String: $((Get-WMIObject Win32_OperatingSystem).version)" }
Else 
{  Write-Host "OS Version String: $((Get-CIMInstance Win32_OperatingSystem).version)" }
```

[Check here](https://github.com/DarwinJS/Undo-WinRMConfig/tree/master/UndoProfiles) whether a profile has already been done for that version.

#### If a profile is already available:

But you know for a fact that it is not working correctly for your scenario, you can update the code and submit a
pull request with your proposed changes (and an explanation over what use case the original code did not cover that your scenario does).
Please be careful about removing existing code as it may be applicable to scenarios you don't experience in your specific configuration.

#### If a profile is NOT already available:

1. Clone the (Undo-WinRMConfig)[https://github.com/DarwinJS/Undo-WinRMConfig] repository.
2. Boot a *COMPLETELY PRISTINE* instance of the specific operating system.
3. Run this code to detect your OS version string:
    ```
    If ($psversiontable.psversion.major -lt 3)
    { Write-Host "OS Version String: $((Get-WMIObject Win32_OperatingSystem).version)" }
    Else 
    {  Write-Host "OS Version String: $((Get-CIMInstance     Win32_OperatingSystem).version)" }
    ```
4. Export the registry key: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN
5. Name the file "Pristine-WSMan-<OSVersionStringFromAbove>" and place it next to Undo-WinRMConfig.ps1
6. Do NOT add any other registry keys to the file
7. Test that your code works - both to return to pristine and that the system can reconfigure wsman with conventional methods.
  1. Configure wsman
  2. Test that it is working
  3. Run your undo-winrmconfig
  4. Test that winrm is NOT working
  5. Configure wsman AGAINT
  6. Test that it is working again
8. Once it is all working, create a pull request for your change

### System Explorer For Snapshots

If you suspect that more changes are going on than the registry keys and firewall settings identified in the code in this repository, you can do your own reverse engineering using System Explorer.

Once you install System Explorer you need to click the "+" to add a new tab and choose "Snapshots".

This hidden little tool is perfect for reverse engineering configuration changes and it is fast, has a great GUI and works all the way through Windows 2016 (many alternatives aren't fast, have cumbersome interfacces or have compatibility problems).

This one liner will install it, then just type "systemexplorer" at the command prompt to start it:
```
If (!(Test-Path env:chocolateyinstall)) {iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex} ; cinst -y systemexplorer #for taking snapshots
```
