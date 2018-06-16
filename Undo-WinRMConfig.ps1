<#
.SYNOPSIS
  Initializes (full read of all bytes) AWS EBS volumes using FIO (File IO Utility).
  See this post for full details on why this code is helpful: https://cloudywindows.io/winrm-for-provisioning---close-the-door-when-you-are-done-eh/
.DESCRIPTION
  CloudyWindows.io DevOps Automation: https://github.com/DarwinJS/CloudyWindowsAutomationCode
  Why and How Blog Post: https://cloudywindows.io/winrm-for-provisioning---close-the-door-when-you-are-done-eh/
  Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/Undo-WinRMConfig/Undo-WinRMConfig.ps1')
  Invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/Undo-WinRMConfig/Undo-WinRMConfig.ps1' -outfile $env:public\Undo-WinRMConfig.ps1 ; & $env:public\Undo-WinRMConfig.ps1 -immediately
  
  Disclaimer - this code was engineered and tested on Server 2012 R2.

  Many windows remote orchestration tools (e.g. Packer) instruct you to completely open up winrm permissions in a way that is not safe for production.
  Usually there is no built in method nor instruction on how to re-secure it or shut it back down.
  The assumption most likely being that you would handle proper configuration as a part of production deployment.
  This is not a least privileged approach - depending on how big your company is and how widely your hypervisor templates are used - this is a disaster waiting to happen.  So I feel leaving it in a disabled state by default is the far safer option.
  To complicate things, if you attempt to secure winrm or shut it down as your last step in orchestration you slam the door on the orchestration system and it marks the attempt as a failure.
  Due to imprecise timing, start up tasks that disable winrm could conflict with a subsequent attempt to re-enable it on the next boot for final configuration steps (especially if you are building a hypervisor template).
  This self-deleting shutdown task performs the disable on the first shutdown and deletes itself.
  If a system shutsdown extremely quickly there is some risk that the shutdown job would not be deleted - but in testing on AWS (very fast shutdown), there have not been an observed problems.
  Updates and more information on ways to use this script are here: https://github.com/DarwinJS/CloudyWindowsAutomationCode/blob/master/Undo-WinRMConfig/readme.md
.COMPONENT
   CloudyWindows.io
.ROLE
  Provisioning Automation
.PARAMETER RunImmediately
  Specifies list of semi-colon seperated number ids of local Devices to initialize.  Devices appear in HKLM:SYSTEM\CurrentControlSet\Services\disk\Enum.
.EXAMPLE
  Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/Undo-WinRMConfig/Undo-WinRMConfig.ps1')
  
  Run directly from github with no parameters - sets up shutdown script to reseal winRM.
.EXAMPLE
  Invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/Undo-WinRMConfig/Undo-WinRMConfig.ps1' -outfile $env:public\Undo-WinRMConfig.ps1 ; & $env:public\Undo-WinRMConfig.ps1 -immediately

  Download dynamically from github and run immediately.
#>
Param (
  [switch]$RunImmediately,
  [string[]]$UndoActions='allundo',
  [switch]$RemoveShutdownScriptSetup
)

#Build the undo script based on parameters
[string]$UndoWinRMScript = ''

If (($UndoActions -icontains 'undofirewall') -OR ($UndoActions -icontains 'allundo') -OR ($UndoActions -icontains 'all'))
{
  $UndoWinRMScript += @'

netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=No
'@
}

If (($UndoActions -icontains 'undowinrm') -OR ($UndoActions -icontains 'allundo') -OR ($UndoActions -icontains 'all'))
{
  $UndoWinRMScript += @'

winrm invoke restore winrm/config '@{}'
winrm invoke restore winrm/config/plugin '@{}'
'@
}

If (($UndoActions -icontains 'undocredssp') -OR ($UndoActions -icontains 'allundo') -OR ($UndoActions -icontains 'all'))
{
  $UndoWinRMScript += @'

winrm invoke restore winrm/config '@{}'
winrm invoke restore winrm/config/plugin '@{}'
'@
}

Write-Host "$UndoWinRMScript"
exit

If ($RunImmediately)
{
  Write-Output 'Disabling PS Remoting Right Now (do NOT execute this over remoting or this code will not complete)...'  
  Invoke-Command -ScriptBlock [Scriptblock]::Create($UndoWinRMScript)
  exit 0
}
else 
{
  Write-Output 'Disabling PS Remoting On Next Shutdown'
}

#Write a file and call it in a machine shutdown script
$psScriptsFile = "C:\Windows\System32\GroupPolicy\Machine\Scripts\psscripts.ini"
$Key1 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Shutdown\0'
$Key2 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Scripts\Shutdown\0'
$keys = @($key1,$key2)
$scriptpath = "C:\Windows\System32\GroupPolicy\Machine\Scripts\Shutdown\disablepsremoting.ps1"
$scriptfilename = (Split-Path -leaf $scriptpath)
$ScriptFolder = (Split-Path -parent $scriptpath)

$selfdeletescript = @"
Start-Sleep -milliseconds 500
Remove-Item -Path "$key1" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$key2" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path $scriptpath -Force  -ErrorAction SilentlyContinue
If (Test-Path $psScriptsFile)
{
  (Get-Content "$psScriptsFile") -replace '0CmdLine=$scriptfilename', '' | Set-Content "$psScriptsFile"
  (Get-Content "$psScriptsFile") -replace '0Parameters=', '' | Set-Content "$psScriptsFile"
}
"@

$selfdeletescript =[Scriptblock]::Create($selfdeletescript)

If ($RemoveShutdownScriptSetup)
{
  Write-Host "Removing previously setup shutdown script"
  Invoke-Command -ScriptBlock $selfdeletescript
  exit $?
}

$UndoWinRMScript += "Register-ScheduledJob -Name CleanUpWinRM -RunNow -ScheduledJobOption @{RunElevated=$True;ShowInTaskScheduler=$True;RunWithoutNetwork=$True} -ScriptBlock $selfdeletescript"

If (!(Test-Path $ScriptFolder)) {New-Item $ScriptFolder -type Directory -force}
Set-Content -path $scriptpath -value $UndoWinRMScript

Foreach ($Key in $keys)
{
  New-Item -Path $key -Force | out-null
  New-ItemProperty -Path $key -Name GPO-ID -Value LocalGPO -Force | out-null
  New-ItemProperty -Path $key -Name SOM-ID -Value Local -Force | out-null
  New-ItemProperty -Path $key -Name FileSysPath -Value "C:\Windows\System32\GroupPolicy\Machine" -Force | out-null
  New-ItemProperty -Path $key -Name DisplayName -Value "Local Group Policy" -Force | out-null
  New-ItemProperty -Path $key -Name GPOName -Value "Local Group Policy" -Force | out-null
  New-ItemProperty -Path $key -Name PSScriptOrder -Value 1 -PropertyType "DWord" -Force | out-null

  $key = "$key\0"
  New-Item -Path $key -Force | out-null
  New-ItemProperty -Path $key -Name "Script" -Value $scriptfilename -Force | out-null
  New-ItemProperty -Path $key -Name "Parameters" -Value $parameters -Force | out-null
  New-ItemProperty -Path $key -Name "IsPowershell" -Value 1 -PropertyType "DWord" -Force | out-null
  New-ItemProperty -Path $key -Name "ExecTime" -Value 0 -PropertyType "QWord" -Force | out-null
}

If (!(Test-Path $psScriptsFile)) {New-Item $psScriptsFile -type file -force}
"[Shutdown]" | Out-File $psScriptsFile
"0CmdLine=$scriptfilename" | Out-File $psScriptsFile -Append
"0Parameters=$parameters" | Out-File $psScriptsFile -Append
