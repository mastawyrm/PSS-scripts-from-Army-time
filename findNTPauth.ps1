$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns\ntp"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()

foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $server1=$false
    $server2=$false
    $auth=$false
    $authKey=$false
    $preout=@()
    foreach ($line in $fileContent){
        $lineSplit = $line.split() | ? {$_}
        if ($line -match '^ntp server'){
            if ($line -match 'key 5'){
                if ($line -match '136.205.6.11'){$server1=$true}
                if ($line -match '136.205.6.12'){$server2=$true}
            }
        }
        if ($line -match '^ntp authenticate'){$auth=$true}
        if ($line -match '^ntp authentication-key 5 md5 QTryh11 7'){$authKey=$true}
        
    }
    if (!$server1){$preout+="ntp server 136.205.6.11 prefer use-vrf default key 5"}
    if (!$server2){$preout+="ntp server 136.205.6.12 use-vrf default key 5"}
    if (!$authKey){$preout+="ntp authentication-key 5 md5 NXntp11`nntp trusted-key 5"}
    if (!$auth){$preout+="ntp authenticate"}
    if ($preout){
        $output+=$preout
        $output+=$IP
    }
}
    



$output > "$scriptDir\outputs\findings.txt"



