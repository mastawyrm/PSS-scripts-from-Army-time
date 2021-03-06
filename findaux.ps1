$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()
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
        if ($line -match '^line'){
            if ($line -match '^line aux'){$one=$true}
            else {$one=$false}
        }
        if ($one) {
            $found=$true
            $output+="line aux 0`ntransport input none`ntransport output none`nno exec`nexec-timeout 0 1`nno password`n"
            $one=$false
        }
    }
    if ($found){$output+="$IP`n"}
}


#$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
$output > "$scriptDir\outputs\findings.txt"



