
$ErrorActionPreference = 'Stop';
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$packageName   = $env:ChocolateyPackageName
$ScriptToRun = "$toolsDir\Undo-WinRMConfig.ps1"

Start-ChocolateyProcessAsAdmin "& `'$ScriptToRun`' -RemoveShutdownScriptSetup"