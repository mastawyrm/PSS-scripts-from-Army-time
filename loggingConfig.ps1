$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''
#$checkline = Get-Content "$scriptDir\outputs\checkline.txt" | Where-Object { $_ -ne '' }



foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    $server=$false
    $aaa=$false
    foreach ($line in $fileContent){
        if ($line -match '^logging server'){
            $lineSplit=$line.Split() | ? {$_}
            $server=$true
            if ($line -notmatch '155.151.61.135' -or $lineSplit[-1] -ne '6'){
                $output+="$line`n"
                $found=$true
            }
        }
        if ($line -match '^logging level aaa'){
            $lineSplit=$line.split() | ? {$_}
            if ($lineSplit[-1] -ne '6'){
                $output+="$line`n"
                $found=$true
            }
            $aaa=$true
        }
    } 
    if (!$aaa){
        $output+="no aaa logging`n"
        $found=$true
    }

    if ($found) {$output+="$IP`n"}
}

$output > "$scriptDir\outputs\findings.txt"

