function Get-userEmail{
    try {
    $userEmail = (Get-CIMInstance CIM_ComputerSystem).PrimaryOwnerName
    } catch {
        Write-Error "No email detected!"
    }
    return $userEmail
}
$userEmail = Get-userEmail
function Get-userName{
    try {
        $userName = (Get-LocalUser -Name $env:USERNAME).FullName
    } catch {
        Write-Error "No user found!"
    }
    return $userName
}
$userName = Get-userName

function Get-deviceName{
    try {
        $deviceName = (Get-CimInstance -ClassName CIM_ComputerSystem).Name
    } catch {
        Write-Error "Couldn't ID device name!"
    }
    return $deviceName
}
$deviceName = Get-deviceName

function Get-userPublicIP{
    try {
        $userPublicIP = (Invoke-WebRequest ipinfo.io/ip).Content.Trim()
    } catch {
        Write-Error "Error identifying public IP!"
    }
    return $userPublicIP
}
$userPublicIP = Get-userPublicIP

function Get-userLocalNetinfo{
    try {
        $userLocalIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*", "*Wi-Fi*" -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress, PrefixOrigin | Out-String
    } catch {
        Write-Error "Error collecting local network info!"
    }
    return $userLocalIP
}
$userLocalIP = Get-userLocalNetinfo

function Get-ssidKey {
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
Write-Host $out

