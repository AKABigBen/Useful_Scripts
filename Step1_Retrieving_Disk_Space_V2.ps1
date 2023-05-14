<#
Author: Benoît Beaulé
Date: March 13, 2023
Version: 2.2
---------------
INTRO 
A common problem we face when it comes to patching servers is low disk space in the System drive. A couple of hundred MB was enough before.
Now the installation may fail if free space is below 10 GB. 12 Gb is a bare minimum.
The following script will retrieve space from locations that have from no to small incidence.
#>

<#
First of all, this command will allow to run the script without modifying the current policy permanently but only for this process.
Use it only if you are prevented to run scripts on a machine.

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

#>

cls
Write-Host "Please wait..."

# Take the Volume size before running the script.
Get-Volume -DriveLetter C
$Before = Get-Volume -DriveLetter C

# Delete RecycleBin content for all users on C:\.
Clear-RecycleBin -DriveLetter C -Force -ErrorAction SilentlyContinue

# Delete each profiles's temp files.
$users = Get-ChildItem $env:HOMEDRIVE\Users
foreach ($user in $users){
  $Folder_u = "$($user.fullname)\AppData\Local\Temp"
    If(Test-Path $Folder_u){
      Remove-Item -Path $Folder_u\* -Recurse -Force -ErrorAction silentlycontinue
  }
}

# Delete the files in "$env:windir\Temp" older than 7 days (or any desired number of days by modifying $t_date variable).
$Folder_w = "$env:windir\Temp"
$t_date=(get-date).AddDays(-7)
gci $Folder_w -Recurse | Where {$_.lastwritetime -lt $t_date} | Remove-Item -Recurse -Force -ErrorAction silentlycontinue

<# Delete the folder "$env:windir\SoftwareDistribution". The Windows Update service (wuauserv) needs to be stopped before and restarted after operation.
And, the folder is regenerated after the operation.

UNCOMMENT THE FOLLOWING SECTION ONLY IF DESPERATE TO RETRIEVE A LITTLE MORE.

#>
<#
$Folder_s="$env:windir\SoftwareDistribution"
Stop-Service wuauserv
Remove-Item $Folder_s -Recurse -Force -ErrorAction silentlycontinue
Start-Service wuauserv
#>

Start-Sleep -Seconds 10

# Take the Volume size after running the script to compare the before and after.
Get-Volume -DriveLetter C
$After = Get-Volume -DriveLetter C
$difference = $before.SizeRemaining - $after.SizeRemaining
$differenceInGB = $difference / 1GB
$differenceInGB = [math]::Round($differenceInGB, 2)
Write-Host "`r`n You recovered $differenceInGB GB !"
