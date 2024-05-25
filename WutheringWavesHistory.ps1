# Define function to get the Epic Games Launcher install directory
function Get-EpicGamesLauncherInstallPath {
    $possiblePaths = @(
        "C:\Program Files\Epic Games\Launcher",
        "C:\Program Files (x86)\Epic Games\Launcher"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    # Fallback to checking the registry if the above paths do not exist
    $regPath = "HKLM:\SOFTWARE\WOW6432Node\Epic Games\EpicGamesLauncher"
    if (Test-Path $regPath) {
        $installPath = Get-ItemProperty -Path $regPath -Name InstallLocation
        return $installPath.InstallLocation
    }

    throw "Epic Games Launcher install path not found."
}

# Define function to get the list of installed games
function Get-InstalledGames {
    $manifestsPath = "C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests"
    if (-Not (Test-Path $manifestsPath)) {
        throw "Manifests directory not found."
    }

    $gameManifests = Get-ChildItem -Path $manifestsPath -Filter *.item
    $games = @()

    foreach ($manifest in $gameManifests) {
        $content = Get-Content -Path $manifest.FullName -Raw | ConvertFrom-Json
        if ($content.InstallLocation -and $content.AppName -and $content.DisplayName) {
            $games += [PSCustomObject]@{
                DisplayName = $content.DisplayName
                AppName = $content.AppName
                InstallLocation = $content.InstallLocation
            }
        } else {
            Write-Output "Manifest file $($manifest.FullName) is missing necessary fields."
        }
    }

    return $games
}

# Define function to get the log file path of a specific game
function Get-GameLogFilePath {
    param (
        [string]$gameName
    )

    $games = Get-InstalledGames
    $game = $games | Where-Object { $_.AppName -eq $gameName }

    if ($null -eq $game) {
        throw "Game '$gameName' not found."
    }

    # Log file path for the specified game
    $logFilePath = Join-Path -Path $game.InstallLocation -ChildPath "Wuthering Waves Game\Client\Saved\Logs\Client.log"
    if (-Not (Test-Path $logFilePath)) {
        throw "Log file not found for game '$gameName'."
    }

    return $logFilePath
}

# Define function to extract the specific URL from the log file
function Extract-UrlFromLog {
    param (
        [string]$logFilePath
    )

    # Read the log file content
    $logContent = Get-Content -Path $logFilePath

    # Define the pattern to extract the sdkJson URL
    $pattern = '"url":"(https:\/\/aki-gm-resources-oversea\.aki-game\.net\/aki\/gacha\/index\.html#\/record[^"]*)"'

    # Search for the URL in the log content
    $matches = [regex]::Matches($logContent, $pattern)
    if ($matches.Count -gt 0) {
        # Return the last match found in the log
        return $matches[$matches.Count - 1].Groups[1].Value
    } else {
        throw "No URL matching the pattern found in the log file."
    }
}

# Example usage
try {
    $launcherPath = Get-EpicGamesLauncherInstallPath

    $installedGames = Get-InstalledGames

    $gameName = "a5faf668dbaf499c8dc2917bf1c346e5"  # Replace with actual game app name
    $logFilePath = Get-GameLogFilePath -gameName $gameName

    # Extract the URL from the log file
    $extractedUrl = Extract-UrlFromLog -logFilePath $logFilePath

    $extractedUrl | Set-Clipboard
    Write-Output $extractedUrl
    Write-Host "URL copied to clipboard." -ForegroundColor Green
} catch {
    Write-Host "Unable to find the convene history." -ForegroundColor Red
}
