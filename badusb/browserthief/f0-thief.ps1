$FileName = "$ENV:tmp/$ENV:USERNAME-BrowserData-$(Get-Date -f hh-mm_dd-MM-yyyy).txt"

$regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'

$edg_history = "$ENV:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\History"
$chr_history = "$ENV:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"

$edg_bkmarks = "$ENV:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
$chr_bkmarks = "$ENV:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"

function readHistory {
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

function readBookmarks {
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