$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\access"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''

foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $catFound=$false
    $nxFound=$false
    $rightline=$false
    $lineNumber=''
    $deny=$false
    foreach ($line in $fileContent){        
        if ($line -match 'Standard IP access list 22'){
            $catFound=$true
        }
        if ($line -match 'IP access list 22|IPV4 ACL 22'){
            $nxFound=$true
        }
        if ($catFound -or $nxFound){
            if ($line -match '10.93.128.0'){
                $rightline=$true
                $lineSplit=$line.split() | ? {$_}
                $lineNumber=$lineSplit[0]
                $scanLine=$lineNumber -replace '0','5'
                if ($catFound){   
                    $output+="ip access-list standard 22`nno $lineNumber`n$lineNumber permit 10.93.128.0 0.0.63.255`n$scanLine permit 155.151.201.128 0.0.0.7`n"
                }
                if ($nxFound){
                    $output+="ip access-list 22`nno $lineNumber`n$lineNumber permit ip 10.93.128.0/18 any`n$scanLine permit ip 155.151.201.128/29 any`n"                
                }
            }
            if ($line -match 'deny'){$deny=$true}
        }
    }
    if (!$deny){Write-Host "NO DENY $IP`n"}
    if ($rightline){$output+="$IP`n`n"}
}



$output > "$scriptDir\multicommands.txt"



