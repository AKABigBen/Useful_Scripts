<#
Author: Benoît Beaulé
Date: March 13, 2023
Version: 1.0
---------------
INTRO 
A common problem we face when it comes to patching servers is low disk space in the System drive. A couple of hundred MB was enough before.
Now the installation may fail if free space is below 10 GB. 12 Gb is a bare minimum.
The following script will delete unnecessary files of outdated components that remained after installing the latest cumulative updates in the $env:windir\WinSxS directory.

Be patient, there's a lot to process here 😉
#>

<#
First of all, this command will allow to run the script without modifying the current policy permanently but only for this process.
Use it only if you are prevented from running scripts on a machine.

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

#>

cls
Write-Host "Please wait, this may take a while..."

# Take the Volume size before running the script.
Get-Volume -DriveLetter C
$Before = Get-Volume -DriveLetter C

<#
If we want the process to be fully automated, we need to import a .REG file. In a Domain environment, the easiest way is to deploy the .REG Key via GPO's.
But here, the .REG Key will be imported from a selected location.
 #>
# Put the path wher the .REG file resides.
$Reg_File_Path = "[Path]\Win_Update_CleanUp.reg"
regedit.exe /s $Reg_File_Path

# Than we run Cleanmgr.exe using the .REG Key configuration that target Win Updates.
Start-Process -FilePath CleanMgr.exe -ArgumentList "/sagerun:100" -Wait

# Take the Volume size after running the script to compare the before and after.
Get-Volume -DriveLetter C
$After = Get-Volume -DriveLetter C
$difference = $before.SizeRemaining - $after.SizeRemaining
$differenceInGB = $difference / 1GB
$differenceInGB = [math]::Round($differenceInGB, 2)
Write-Host "`r`n You recovered $differenceInGB GB !"
