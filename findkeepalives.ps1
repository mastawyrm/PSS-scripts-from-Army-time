$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''
$oneIP = ''
$twoIP = ''
$bothIP = ''
$prompt = ''
#$checkline = Get-Content "$scriptDir\outputs\checkline.txt" | Where-Object { $_ -ne '' }



foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    $one=$false
    $two=$false
    foreach ($line in $fileContent){
        if ($line -match '#$' -or $line -match '>$') {$prompt=$line}
        if ($line -match 'tcp-keepalives-in'){$one=$true}
        if ($line -match 'tcp-keepalives-out'){$two=$true}
    } 
    if (!$one) {$output+="service tcp-keepalives-in`n"}
    if (!$two) {$output+="service tcp-keepalives-out`n"}
    if (!$one -or !$two) {$output+="$IP`n"}
}



#$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
$output > "$scriptDir\outputs\findings.txt"

