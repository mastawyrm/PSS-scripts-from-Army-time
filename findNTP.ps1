$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()

foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $hostname=''
    $peers=''
    $ntp=$false
    $11=$false
    $12=$false
    $found=$false
    foreach ($line in $fileContent){
        if ($line -match '# sh vers'){
            $lineSplit = $line.split('#')
            $hostname=$lineSplit[0]
        }
        if ($line -match '> sh vers'){
            $lineSplit = $line.split('>')
            $hostname=$lineSplit[0]
        }
        if ($line -match $hostname){
            $ntp=$false
        }
        if ($line -match 'sh ntp peer-status'){
            $ntp=$true
        }
        if ($ntp){
            $lineSplit = $line.split() | ? {$_}
            if ($line -match '136.205.6.11'){$11=$true}
            if ($line -match '136.205.6.12'){$12=$true}
            if ($line -match '^Total peers'){
                if ($lineSplit[-1] -ne '2'){
                    $output+=$lineSplit[-1]
                    $found=$true
                }
            }
        }
    }
    if (!$11){
        $output+="136.205.6.11 missing"
        $found=$true
    }
    if (!$12){
        $output+="136.205.6.12 missing"
        $found=$true
    }
    if ($found){$output+="$IP"}
    
}


$output > "$scriptDir\outputs\findings.txt"



