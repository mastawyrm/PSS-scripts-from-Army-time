$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()
$checkLine='tacacs-server host 155.151.61.133 key 7 "136205VHKqohh!@" timeout 60 ','tacacs-server host 155.151.61.134 key 7 "136205VHKqohh!@" timeout 60 '


foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $aaa=$false
    $one=$false
    $two=$false
    $found=$false
    foreach ($line in $fileContent){
        if ($line -notmatch '^   '){
            $aaa=$false
        }
        if ($line -match '^aaa group server'){
            $aaa=$true
        }

        if ($aaa){
            if ($line -match '    server 155.151.61.133'){$one=$true}
            if ($line -match '    server 155.151.61.134'){$two=$true}
        }
        if ($line -match 'tacacs-server host'){
            if ($checkLine -notcontains $line){
                $output+=$line
                $found=$true
            }
        }
    } 
    if (!$one) {
        $output+='133 missing'
        $found+$true
    }
    if (!$two){
        $output+='134 missing'
        $found=$true
    }
    if ($found) {$output+=$IP}
}


$output > "$scriptDir\outputs\findings.txt"

