$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
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
            if ($line -match '^line con'){$one=$true}
            else {$one=$false}
        }
        if ($one) {
            if ($line -match 'timeout'){
                $two=$true
                $parts=$line.split() | ? {$_}
                $time=$parts[-1] -as [int]
                if ($time -gt 10){
                    $output+="$line`n"; $found=$true}
            }
        }
    }
    if (!$two){$output+="session-timeout 5`n$IP`n"}
    if ($found){$output+="$IP`n"}
}


#$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
$output > "$scriptDir\outputs\findings.txt"



