$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()
$checkNames='admin','BigRed1','OPORD1337','swinds','CiscoPrime'



foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    foreach ($line in $fileContent){
        if ($line -match '^username'){
            $lineSplit=$line.Split() | ? {$_}
            if ($checkNames -notcontains $lineSplit[1]){
                $output+=$line
                $found=$true
            }
        }
    } 
    if ($found) {$output+=$IP}
}


$output > "$scriptDir\outputs\findings.txt"

