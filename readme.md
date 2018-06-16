
# Undo-WinRMConfig Documentation

- [Undo-WinRMConfig Documentation](#undo-winrmconfig-documentation)
- [Community Testing Help Needed!](#community-testing-help-needed)
- [The Important Security Problem](#the-important-security-problem)
- [This Solution](#this-solution)
- [This Code Implementation](#this-code-implementation)
- [The Disclaimers](#the-disclaimers)
- [Ways to Run It](#ways-to-run-it)
    - [Direct Run From GitHub](#direct-run-from-github)
        - [Run Undo Process At Shutdown (default)](#run-undo-process-at-shutdown-default)
        - [Run Immediately (Careful!)](#run-immediately-careful)
        - [Remove Shutdown Job Before It Runs](#remove-shutdown-job-before-it-runs)
    - [Place On Image Template Without Running](#place-on-image-template-without-running)
    - [Chocolatey Package](#chocolatey-package)
        - [Run At Shutdown (default)](#run-at-shutdown-default)
        - [Run Immediately (Careful!)](#run-immediately-careful)
        - [Remove Shutdown Job Before It Runs](#remove-shutdown-job-before-it-runs)
# Community Testing Help Needed!
It is not possible for me to test all OS versions and PowerShell versions running directly and via Chocolatey.  Thinking community members could pick scenarios relevant to them.  Below are some of the desirable tests.  Problems reports should be submitted to: https://github.com/DarwinJS/CloudyWindowsAutomationCode/issues

Tests for each below scenario:
* "does it execute at all" but also 
* "does it effectively undo WinRM configuration (not disable)" and  
* "Can WinRm be rconfigured again with **conventional instructions** after this has run"

Script Functionality:
* (Default) Run and setup shutdown job (choco install)
* Run immediately to Undo WinRM Configuration (don't run over remoting) (choco install -params '"/RunImmediately"' )
* -RemoveShutdownScriptSetup (Choco Uninstall) - removes shutdown job before it runs (it self deletes during actual operation)

Run Scope:
* Run Over Remoting (Choco / non-choco)
* Run Under System Account (choco / non-choco)
* Run under a system account service (choco / non-choco)

OS / PowerShell Scope:
* Windows 7 / 2008 R2, Windows 8.1 / 2012 R2, Windows 10 / 2016

# The Important Security Problem
Many windows remote orchestration tools (e.g. Packer) instruct you to open up winrm permissions in a way that is not safe for (nor intended for) use in production.  (e.g. https://www.packer.io/docs/builders/ncloud.html#sample-code-of-template-json)  Generally there is no guidance on how to re-secure it nor even a reminder to do so.  The assumption most likely being that you would handle proper winrm re-configuration as a part of provisioning the machine - but in many organizations systems preparation may be the only use of WinRM - so it is forgotten.  Or maybe whatever you use to re-configure it does not actively manage one of the permissive settings used during machine provisioning.

Sysprep does not revert WinRM configuration to a pristine state and I checked with Microsoft and there is not an API call to revert to pristine either.

Keep in mind that disabling WinRM is not the goal - but rather returning it to a pristine state (or as close as possible).  This allows it to be reconfigured using conventional instructions - including the possibility that subsequent system preparation automation (like packer) will be used to prepare a new template image based on a previously prepared image template.

Leaving WinRM in this state is not a least privileged approach for several reasons: 

- sysprep does not automatically deconfigure WinRM.
- it is not secure at rest nor by default once booted.
- it is unlikely the next user of the image template would think that WinRM has been preconfigured with permissive settings and that they would need to deal with it.
- frequently images used for testing are not joined to a domain, so even if these settings are handled by a GPO in production environments - not all uses of the image template will necessarily have the benefit of such a GPO configuration.

Depending on how big your company is and how widely your hypervisor templates are used - this is a disaster waiting to happen.  So I feel leaving it in a disabled state by default is the far safer option.

# This Solution
This self-deleting shutdown task performs the disable on the first shutdown and deletes itself.  It can also run immediately - which only works if you are not using WinRM to run it.

# This Code Implementation
The goal of this code is NOT to disable WinRM, but to set WinRM configuration back to as close to pristine as possible so that it can be reconfigured as necessary.
At first glance, the code will appear a bit over complex, but that complexity has some rationale behind it:
1. If you attempt to revert WinRM configuration as your last step in automation that is using WinRM to access the machine - you slam the door on your own fingers and the automation will most likely exit with an error.  This is the exact scenario for Packer.
2. Due to imprecise timing, **startup** tasks that disable winrm could conflict with a subsequent attempt to re-enable it on the next boot for final configuration steps.
3. Setting up a shutdown script requires some manipulation of GPO files and registry keys.  To ensure appropriate security permissions no matter what user it used to execute this code, the setup is done via a scheduled job.

If you have the luxury of running this code locally on the build machine without using WinRM, then you can use the "RunImmediately" switch to skip the above convolutions.

FYI: If a system shuts down extremely quickly there is some risk that the shutdown job would not be deleted - but in testing on AWS (very fast shutdown), there have not been an observed problems.

# The Disclaimers
This code was engineered by reversing the commands required to configure winrm to be used for system preparation by Packer.  In that regard it results in returning WinRM configuration to a state similar to, but quite possibly not identical to pristine defaults.

If your WinRM configuration process involves configuring additional items, the reversal of those settings may need to be added to this script.  You could create a customized copy or submit an issue or PR against this script.

This code was engineered and tested on Server 2012 R2 / PowerShell 4 - it is unknown how well it works for earlier versions.
# Ways to Run It

## Direct Run From GitHub

### Run Undo Process At Shutdown (default)
    Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/Undo-WinRMConfig/Undo-WinRMConfig.ps1')

### Run Immediately (Careful!)
**Caution:** If you run this command while remoting in, you will slam the remoting connection closed and have a non-zero exit code.
    
    Invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/Undo-WinRMConfig/Undo-WinRMConfig.ps1' -outfile $env:public\Undo-WinRMConfig.ps1 ; & $env:public\Undo-WinRMConfig.ps1 -RunImmediately

### Remove Shutdown Job Before It Runs
    
    Invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/Undo-WinRMConfig/Undo-WinRMConfig.ps1' -outfile $env:public\Undo-WinRMConfig.ps1 ; & $env:public\Undo-WinRMConfig.ps1 -RemoveShutdownScriptSetup

## Place On Image Template Without Running
    Invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/Undo-WinRMConfig/Undo-WinRMConfig.ps1' -outfile $env:public\Undo-WinRMConfig.ps1

## Chocolatey Package

**ATTENTION: While this code is in the community feedback phase, I have it on a test feed.  It will be available via chocolatey.org when the code is finalized**

### Run At Shutdown (default)
    choco install undo-winrmconfig-at-shutdown -confirm -source https://www.myget.org/F/chocotesting/api/v2/

### Run Immediately (Careful!)
**Caution:** If you run this command while remoting in, you will slam the remoting connection closed and have a non-zero exit code.

    choco install undo-winrmconfig-at-shutdown -confirm -params '"/RunImmediately"' -source https://www.myget.org/F/chocotesting/api/v2/

### Remove Shutdown Job Before It Runs
    
    choco uninstall undo-winrmconfig-at-shutdown -confirm
    