$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

."$scriptDir\credfile.ps1"
$PWord=ConvertTo-SecureString –String "$Pass" -AsPlainText -Force
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $PWord

."$scriptDir\functions.ps1"


$neighborDir = "$scriptDir\outputs\neighbor"
$workingdir = $neighborDir
$firststepIP = @(Get-Content "$scriptDir\IPs\restartIPs.txt" | Where-Object { $_ -ne '' })
$workingIPs = @(Get-Content "$scriptDir\IPs\IPs.txt" | Where-Object { $_ -ne '' })

$nextIPs = @($firststepIP)
$step = 0

Do {
    searchNeighbor -IPfile $nextIPs -workingdir $workingdir -cred $cred
   
    $workingfiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
    $step ++
    $nextIPs = @()
    foreach ($filename in $workingfiles) {
        $content = Get-Content $filename | Where-Object { $_ -ne '' }
        $IPsfortest = @()
        ForEach ($object in $content) {
            $IPout =  ExtractValidIPAddress -String $object
            if ($IPout) {$IPsfortest += $IPout}
        } 
        $newIPsthisround = @()
        $newIPsthisround = testIPs -IPsfortest $IPsfortest -currentIPs $workingIPs
        if ($newIPsthisround){
            $workingIPs += $newIPsthisround
            $nextIPs += $newIPsthisround
        }
        
    }
    md "$scriptDir\outputs\neighbor\step$step" -force
    $workingdir = "$scriptDir\outputs\neighbor\step$step"
    $nextIPs > "$neighborDir\step$step`IPs.txt"
    $nextIPs = @(Get-Content "$neighborDir\step$step`IPs.txt" | Where-Object { $_ -ne '' })
} while ($nextIPs)

$brokenIP = Get-Content "$scriptDir\IPs\noresponse.txt"

$finalList = testIPs -IPsfortest $workingIPs -currentIPs $brokenIP
$finalList > "$scriptDir\IPs\all_IPs_$(get-date -f yyyy.MM.dd).txt"

