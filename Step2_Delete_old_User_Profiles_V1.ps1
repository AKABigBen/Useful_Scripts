<#
Author: Benoît Beaulé
Date: March 13, 2023
Version: 1.1
---------------
INTRO 
A common problem we face when it comes to patching servers is low disk space in the System drive. A couple of hundred MB was enough before.
Now the installation may fail if free space is below 10 GB. 12 Gb is a bare minimum.
The following script will retrieve space by deleting user profiles older than 2 years (or any desired number of days by modifying $daysThreshold variable).

We don't want to delete the Default nor the Public profiles. Default is hidden so nothing has to be done.
Public, doesn't contain NTUSER.DAT. But we will target only the profiles that have it.

However, we want to delete a profile that meet 3 conditions:
User's last logon time AND their profile directory's LastWriteTime are older than the threshold date AND if the profile has a NTUSER.DAT file.
By choosing a 2 years threshold, we will prevent the deletion of a profile that is still or might be in use.
But we'll get rid of those that lies there for too long and for nothing. By experience, a lot of space can be retrieved there.

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

# Define the number of days after which a profile should be deleted.
$daysThreshold = 730

# Get a list of all user profile directories.
$userDirs = Get-ChildItem -Path "$env:HOMEDRIVE\Users" -Directory

# Define the logon event ID.
$logonEventId = 4624

# Loop through each user profile directory and check if it's older than the threshold date.
foreach ($userDir in $userDirs) {
    # Get the username from the profile directory name.
    $userName = $userDir.Name

    # Get the Event Viewer log for Security events.
    $log = Get-WinEvent -FilterHashtable @{LogName="Security";Id=$logonEventId} -ErrorAction SilentlyContinue

    # Filter the log to show only events for the current user.
    $userLog = $log | Where-Object { $_.Properties[5].Value -eq $userName }

    # Sort the log by time and get the most recent event.
    $lastLogonEvent = $userLog | Sort-Object TimeCreated -Descending | Select-Object -First 1

    # Get the LastWriteTime of the user's profile directory.
    $lastWriteTime = $userDir.LastWriteTime

    # Check if the user's last logon time AND their profile directory's LastWriteTime are older than the threshold date AND if the profile have a NTUSER.DAT file.
    if (($lastLogonEvent.TimeCreated -lt (Get-Date).AddDays(-$daysThreshold)) -and ($lastWriteTime -lt (Get-Date).AddDays(-$daysThreshold) -and (Test-Path -Path "$($userDir.FullName)\ntuser.dat"))) {
        # Delete the user's profile directory.
        Write-Host "Deleting profile directory for user $($userName)"
        
      <# Until you uncomment the following line, nothing will be done. You can run the script as it is to know which profiles will be targeted as a 1rst step if you want. 
         The profile list will be displayed at the end. #>
       
     #Get-CimInstance -Class Win32_UserProfile | Where-Object { $userDir.FullName } | Remove-CimInstance -ErrorAction SilentlyContinue

    }
}

# Take the Volume size after running the script to compare the before and after.
Write-Host
Get-Volume -DriveLetter C
$After = Get-Volume -DriveLetter C
$difference = $before.SizeRemaining - $after.SizeRemaining
$differenceInGB = $difference / 1GB
$differenceInGB = [math]::Round($differenceInGB, 2)
Write-Host "`r`n You recovered $differenceInGB GB !"
