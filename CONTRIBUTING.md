
## 
 
### Run The Code

If it is the case, the code will emit the fact that your OS variant is not yet supported.

### Find Out What Your Major + Minor OS Version Is:

Run this code to emit the version string that Undo-WinRMConfig will use.

**IMPORTANT**: Undo-WinRM only uses the Major + Minor versions to avoid a ton of duplicate registry keys for build level variations of Windows.  If you find a build-level variation of the wsman pristine registry key, please file an issue as it may require some re-thinking of how the core engine searches for and finds the right registry data for the pristine key (e.g. we may have to support build level lookup when, and only when, there are build-level variations in the pristine wsman reg key)

```
If ($psversiontable.psversion.major -lt 3)
{ $OSMajorMinorVersionString = @(([version](Get-WMIObject Win32_OperatingSystem).version).major,([version](Get-WMIObject Win32_OperatingSystem).version).minor) -join '.'}
Else 
{ $OSMajorMinorVersionString = @(([version](Get-CIMInstance Win32_OperatingSystem).version).major,([version](Get-CIMInstance Win32_OperatingSystem).version).minor) -join '.'}
Write-Host $OSMajorMinorVersionString
```


#### If a profile is already available, but you think it needs fixing:

But you know for a fact that it is not working correctly for your scenario, you can update the code and submit a
pull request with your proposed changes (and an explanation over what use case the original code did not cover that your scenario does).
Please be careful about removing existing code as it may be applicable to scenarios you don't experience in your specific configuration.

#### If a profile is NOT already available:

1. Clone the (Undo-WinRMConfig)[https://github.com/DarwinJS/Undo-WinRMConfig] repository.
2. Boot a *COMPLETELY PRISTINE* instance of the specific operating system.
3. Run this code to detect your OS version string:
    ```
    If ($psversiontable.psversion.major -lt 3)
    { $OSMajorMinorVersionString = @(([version](Get-WMIObject Win32_OperatingSystem).version).major,([version](Get-WMIObject Win32_OperatingSystem).version).minor) -join '.'}
    Else 
    { $OSMajorMinorVersionString = @(([version](Get-CIMInstance Win32_OperatingSystem).version).major,([version](Get-CIMInstance Win32_OperatingSystem).version).minor) -join '.'}
    Write-Host $OSMajorMinorVersionString
    ```
4. Export the registry key: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN
5. Name the file "Pristine-WSMan-<OSVersionStringFromAbove>" and carefully add it as a here string in Undo-WinRMConfig.ps1.  Follow the other examples to ensure that the OS lookup routine will find your addition.  Notice that only the first two segments of the OS Version number are used.
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
