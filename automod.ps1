# Helper utility to autozip and copy a mod to BeamMP's resource folder
# Usage: automod.ps1 <modPath> <beammpResourcePath>
# Example: automod.ps1 ".\automod.ps1 .\Resources\Client\floodBeamMP\ C:\Users\myUser\AppData\Roaming\BeamMP-Launcher\Resources"

if ($args.Count -lt 2) {
    Write-Error "Usage: automod.ps1 <modPath> <beammpResourcePath>"
    exit
}

$ModPath = $args[0]
$BeamMPResourcePath = $args[1]

if ($ModPath.EndsWith("\") -or $ModPath.EndsWith("/")) {
    $ModPath = $ModPath.Substring(0, $ModPath.Length - 1)
}
if ($BeamMPResourcePath.EndsWith("\") -or $BeamMPResourcePath.EndsWith("/")) {
    $BeamMPResourcePath = $BeamMPResourcePath.Substring(0, $BeamMPResourcePath.Length - 1)
}

# Check if the mod path exists
if (!(Test-Path $ModPath)) {
    Write-Error "Mod path does not exist: $ModPath"
    exit
}

$ModName = Split-Path $ModPath -Leaf

# Check if the BeamMP resource path exists
if (!(Test-Path $BeamMPResourcePath)) {
    Write-Error "BeamMP resource path does not exist: $BeamMPResourcePath"
    exit
}

# Watcher stuff
$Watcher = New-Object System.IO.FileSystemWatcher
$Watcher.Path = Resolve-Path -Path $ModPath
$Watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite, [System.IO.NotifyFilters]::FileName, [System.IO.NotifyFilters]::DirectoryName
$Watcher.Filter = "*.*"
$Watcher.IncludeSubdirectories = $true
$Watcher.EnableRaisingEvents = $true

$ChangeTypes = [System.IO.WatcherChangeTypes]::Created, [System.IO.WatcherChangeTypes]::Changed, [System.IO.WatcherChangeTypes]::Deleted
$WatcherTimeout = 1000
$CopyTimeout = 2000
$LastChange = [DateTime]::MinValue

function Invoke-SomeAction {
    param (
        [Parameter(Mandatory)]
        [System.IO.WaitForChangedResult]
        $ChangeInformation
    )
  
    Write-Host "File updated: $($ChangeInformation.Name)" -ForegroundColor Green

    # Zip the folder
    $zip = "$ModPath.zip"
    if (Test-Path $zip) {
        Remove-Item $zip
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Create ZIP file and handle a common error
    try {
        [System.IO.Compression.ZipFile]::CreateFromDirectory($ModPath, $zip)
    } catch {
        Write-Host "Failed creating zip: $($_)" -ForegroundColor Red
    }

    # Delete the old folder in the BeamMP resource path
    $old = "$BeamMPResourcePath/$ModName.zip"
    if (Test-Path $old) {
        Remove-Item $old
    }

    # Copy the new folder to the BeamMP resource path
    Copy-Item $zip $old

    Write-Host "Sucessfully updated mod" -ForegroundColor Magenta
}

try {
    Write-Host "Watching $ModPath for changes..." -ForegroundColor DarkYellow
    while ($true) {
        $change = $Watcher.WaitForChanged($ChangeTypes, $WatcherTimeout)
        if ($change.TimedOut) {
            continue
        }

        # Wait a few seconds until we can copy the files again
        if ([DateTime]::Now - $LastChange -lt [TimeSpan]::FromMilliseconds($CopyTimeout)) {
            Write-Host "Waiting for changes to finish..." -ForegroundColor DarkYellow
            Start-Sleep -Milliseconds $CopyTimeout
            Invoke-SomeAction $change
            continue
        }

        $LastChange = [DateTime]::Now
        Invoke-SomeAction $change
    }
} catch {
    Write-Error $_
}