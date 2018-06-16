
$ErrorActionPreference = 'Stop';
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$packageName   = $env:ChocolateyPackageName
$ScriptToRun = "$toolsDir\Undo-WinRMConfig.ps1"

$pp = Get-PackageParameters

$RunImmediatelyValue = $False
if ($pp.RunImmediately) {
  Write-Host "/RunImmediately was used, will run WinRM undo and exit..."
  Start-ChocolateyProcessAsAdmin "& `'$ScriptToRun`' -RunImmediately"
}
else 
{
  Start-ChocolateyProcessAsAdmin "& `'$ScriptToRun`'"  
}
