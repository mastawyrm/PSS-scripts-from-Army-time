$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''
$22 = @()
$22+="access-list 22 permit 155.151.116.0 0.0.0.63","access-list 22 permit 155.151.117.0 0.0.0.63","access-list 22 permit 136.205.187.0 0.0.0.15","access-list 22 permit 155.151.61.128 0.0.0.63","access-list 22 permit 155.151.43.144 0.0.0.15","access-list 22 permit 10.93.128.0 0.0.31.255","access-list 22 permit 158.9.246.16 0.0.0.15"

foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    $22count=0
    $lineCount=0
    $vty=$false
    foreach ($line in $fileContent){        
        if ($line -match 'access-list 22'){
            if ($22 -contains $line){$22count++}
        }
        if ($line -match 'line vty'){
            $lineCount++
            $vty=$true
        }
        if ($vty){
            if ($line -match 'access-class'){
                $lineSplit = $line.split()
                if ($lineSplit[2] -ne '22'){
                    $output+="$line`n"
                    $found=$true
                }
            }
        }
    }
    if ($22count -ne 7){
        $found=$true
        $output+="22 wrong, count=$22count`n"
    }
    if ($found){$output+="$IP`n"}
}



$output > "$scriptDir\outputs\findings.txt"



