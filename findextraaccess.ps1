$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\access"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''

foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    $rightline=$false
    foreach ($line in $fileContent){        
        if ($line -match 'Standard IP access list 22'){
            $found=$true
        }
        
        if ($found){
            if ($line -match '155.151.117.0'){
                if ($line -notmatch 'wildcard bits 0.0.0.63'){
                    $rightline=$true
                    $output+="$line`n"
                    break
                }
            }
        }
    }

    if ($rightline){$output+="$IP`n`n"}
}



$output > "$scriptDir\outputs\findings.txt"



