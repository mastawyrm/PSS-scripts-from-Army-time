$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()

foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $hostname=''
    $kickstart=''
    $system=''
    $software=$false
    foreach ($line in $fileContent){
        if ($line -match '# sh vers'){
            $lineSplit = $line.split('#')
            $hostname=$lineSplit[0]
        }
        if ($line -match '> sh vers'){
            $lineSplit = $line.split('>')
            $hostname=$lineSplit[0]
        }
        if ($line -eq 'Software'){
            $software=$true
        }
        if ($line -eq 'Hardware'){
            $software=$false
        }
        if ($software){
            if ($line -match 'kickstart:'){$kickstart=$line}
            if ($line -match 'system:'){$system=$line}
        }
    }
    $count++
    if ($hostname -and $kickstart){$output+="$hostname $kickstart $IP"}
    if ($hostname -and $system){$output+="$hostname $system $IP"}
    else {$output+=$filename}
}


$output > "$scriptDir\outputs\NX_versions.txt"



