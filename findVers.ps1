$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''
$count=0

foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $hostname=''
    $vers=''
    foreach ($line in $fileContent){
        if ($line -match '#sh vers'){
            $lineSplit = $line.split('#')
            $hostname=$lineSplit[0]
        }
        if ($line -match '>sh vers'){
            $lineSplit = $line.split('>')
            $hostname=$lineSplit[0]
        }
        if ($line -match 'RELEASE SOFTWARE'){
            $lineSplit = $line.split(',')
            $vers=$lineSplit[-2]
            break
        }
    }
    $count++
    if ($hostname -and $vers){$output+="$hostname $vers $IP`n"}
    else {$output+="$filename`n"}
}


#$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
$output > "$scriptDir\outputs\versions.txt"



