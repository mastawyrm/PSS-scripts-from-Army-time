$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''
$oneIP = ''
$twoIP = ''
$bothIP = ''


foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    $one=$false
    $two=$false
    foreach ($line in $fileContent){
        if ($line -match '^logging buffered' -or $line -match '^logging console'){
            if ($line -notmatch 'informational$'){$output+="$line`n"; $one=$true}
        }
    }
    if ($one){$output+="$IP`n"}
}



#$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
$output > "$scriptDir\outputs\findings.txt"

