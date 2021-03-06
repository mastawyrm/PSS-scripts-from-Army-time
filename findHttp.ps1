$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''

foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $http=$false
    $https=$false
    foreach ($line in $fileContent){        
        if ($line -match 'ip http'){
            if ($line -eq 'ip http server'){
                $http=$true
            }
            if ($line -eq 'ip https secure-server'){
                $https=$true
            }
        }
    }
    if ($http -and !$https){$output+="$IP`n"}
}



$output > "$scriptDir\outputs\findings.txt"



