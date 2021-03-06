$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''

foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $retries=''
    $found=$false
    foreach ($line in $fileContent){        
        if ($line -match 'ip ssh authentication-retries'){
            $lineSplit = $line.split() | ? {$_}
            $retries = $lineSplit[-1] -as [int]
            if ($retries -gt 3){
                $found=$true
                $output+="$line`n"
            }
        }
    }
    if ($found){$output+="$IP`n"}
}



$output > "$scriptDir\outputs\findings.txt"



