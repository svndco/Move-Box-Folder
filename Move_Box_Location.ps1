<#
.SYNOPSIS
Script to manage the Box Drive location by moving it between C: and D: drives.

.DESCRIPTION
This script allows users to move the Box Drive location between C: and D: drives. 
It stops the Box process if it's running, moves the Box folder and its contents, 
creates symbolic links (aliases), and starts the Box application.

.AUTHOR
Jeremy Allen

.VERSION
1.0
#>

# Clear the screen
Clear-Host

# Stop the Box process if it's running
$boxProcess = Get-Process -Name "Box" -ErrorAction SilentlyContinue
if ($boxProcess) {
    Stop-Process -Name "Box" -Force
    Write-Host "Box process stopped."
}

# Function to wait for one second
function Wait-OneSecond {
    Start-Sleep -Seconds 1
}

# Set the paths
$originalFolder = "C:\Users\Virtual\AppData\Local\Box\Box"
$aliasPathOnC = "C:\Users\Virtual\AppData\Local\Box"
$newFolder = "D:\BoxCache\"
$customFolder = "D:\"
$boxFolderPath = "D:\"
$sourcePath = "D:\BoxCache\Box"
$targetPath = "C:\Users\Virtual\AppData\Local\Box\Box"

# Define the registry key path
$registryKeyPath = "HKLM:\SOFTWARE\Box\Box"

# Define the name and value of the registry string value
$valueName = "CustomBoxLocation"
$valueData = $boxFolderPath

# Move the Box folder and its contents to the new location using robocopy
function Move-Items {
    param (
        [string] $source,
        [string] $destination
    )

    # Move the folder and its contents from source to destination using robocopy
    robocopy $source $destination /MOVE /E /NP > $null
}

# Prompt the user to choose an action for managing Box Drive location
Write-Host "Move Box Location"
Write-Host "C"
Write-Host "D"
$choice = Read-Host "Enter your DRIVE choice:"

switch ($choice) {
    "C" {
        # Remove the existing Box folder if it exists
        Remove-Item -Path $aliasPathOnC -Force -Recurse -ErrorAction SilentlyContinue

        # Wait for 2 seconds
        Start-Sleep -Seconds 2

        # Move the folder from D to C
        Move-Items -source $newFolder -destination $aliasPathOnC

        # Define the registry key path

        # Remove the CustomBoxLocation registry entry to restore Box Drive to the original location
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Box\Box" -Name "CustomBoxLocation" -ErrorAction SilentlyContinue

        # Start the Box application
        Start-Process "C:\Program Files\Box\Box\Box.exe"
    }
    "D" {
        # Create the destination directory if it does not exist
        if (-not (Test-Path -Path $newFolder -PathType Container)) {
            New-Item -ItemType Directory -Path $newFolder -Force | Out-Null
        }

        # Move the entire Box folder and its contents to the new location
        Move-Item -Path $originalFolder -Destination $newFolder -Force

        # Create the Box alias on C for the new location
        if (-not (Test-Path -Path $aliasPathOnC -PathType Container)) {
        cmd /c mklink /d $aliasPathOnC $newFolder
       }

        # Check if the specified folder path exists
    if (-not (Test-Path -Path $boxFolderPath -PathType Container)) {
        Write-Host "Error: The specified folder path '$boxFolderPath' does not exist or is not accessible."
        exit
    }

    # Create the symbolic link (alias)
    New-Item -Path $targetPath -ItemType SymbolicLink -Value $sourcePath -Force

    Write-Host "Box Drive location set to: $newFolder"
    Write-Host "Box Drive moved to D:"


        # Set the registry value
        New-ItemProperty -Path $registryKeyPath -Name $valueName -Value $valueData -PropertyType String -Force | Out-Null

        # Start the Box application
        Start-Process "C:\Program Files\Box\Box\Box.exe"
    }
    default {
        Write-Host "Invalid choice. Please enter 'C' to move Box Drive to C: or 'D' to move it to D:"
    }
}
