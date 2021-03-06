$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()
$bldgs = @()
$types = @()
$hostnames = @()
$oneIP = ''
$twoIP = ''
$bothIP = ''
$hostFile = Get-Content "$scriptDir\outputs\hostnames.txt" | Where-Object { $_ -ne '' }


foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    foreach($line in $fileContent){
        if ($line -match 'sh vers'){
            $hostname=$line -replace '#sh vers',''
            if ($hostnames -notcontains $hostname){$hostnames+=$hostname}
            break
        }
    }
    $hostparts=$hostname.split('-')
    if ($hostparts[2] -eq 'raal'){
        if ($bldgs -notcontains $hostparts[3]){$bldgs+=$hostparts[3]}
        if ($types -notcontains $hostparts[0]){$types+=$hostparts[0]}
    }
}




#$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
#$output > "$scriptDir\outputs\findings.txt"


