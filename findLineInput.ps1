$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''

foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    foreach ($line in $fileContent){        
        if ($line -match '^ transport input'){
            if ($line -ne ' transport input ssh'){
                $output+="$line`n"
                $found=$true
            } 
        }
    }
    if ($found){$output+="$IP`n"}
}



$output > "$scriptDir\outputs\findings.txt"



