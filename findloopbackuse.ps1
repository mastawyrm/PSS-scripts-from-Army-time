$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$loopbacks = Get-Content "$scriptDir\outputs\loopbacks.txt" | Where-Object { $_ -ne '' }
$output = ''
$oneIP = ''
$twoIP = ''
$bothIP = ''
$prompt = ''
$checkline = Get-Content "$scriptDir\outputs\checkline.txt" | Where-Object { $_ -ne '' }



foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    $one=$false
    $two=$false
    $int=''
    $boolList = New-Object bool[] 7
    foreach ($line in $loopbacks){
        if ($line -match $IP){$int=$line -replace "$IP ",'';break}
    }
    foreach ($line in $fileContent){
        if ($line -match '#$' -or $line -match '>$') {$prompt=$line}
        $count=0
        foreach ($entry in $checkline) {
            if ($line -match $entry) {
                $boolList[$count]=$true
                if ($line -notmatch $int){$output+="$IP $entry $int $line`n";$boolList[$count]=$false}
            }
            $count++
        }

    }
    $count=0
    $check=$false
    foreach ($entry in $checkline){
            if (!$boolList[$count]){$oneIP+="$entry $int`n";$check=$true}
            $count++
    }
    if ($check){$oneIP+="$IP`n"}
    
#    if (!$one -and $two) {$bothIP+="$IP $prompt`n"}
#    elseif (!$one) {$oneIP+="$IP`n"}
#    elseif ($two) {$twoIP+="$IP`n"}
}



$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
$output > "$scriptDir\outputs\findings.txt"

