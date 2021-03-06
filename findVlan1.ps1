$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()
#$checkline = Get-Content "$scriptDir\outputs\checkline.txt" | Where-Object { $_ -ne '' }
$fileCount=0


foreach ($filename in $workingFiles) {
    $fileCount+=100
    Write-Progress "Files done" "Percent" -PercentComplete ($fileCount/$workingFiles.Length)
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    $vlan1=$false
    $start=$false
    $portLoc=''
    $lineCount=0
    foreach ($line in $fileContent){
        $lineCount+=100
        Write-Progress -Id 1 "Lines done" "Percent of $IP" -PercentComplete ($lineCount/$fileContent.length)
        if ($vlan1){
            $lineSplit = $line.Split() | ? {$_}
            
            if ($lineSplit[0] -eq 'VLAN'){
                if ($lineSplit[1] -eq 'Type'){
                    $vlan1=$false
                    $portLoc=''
                    break
                }
                if ($lineSplit[1] -eq 'Name'){
                    $portLoc = $line.IndexOf('Ports')
                }
            }
            if ($lineSplit[0] -eq '1' -and $lineSplit[1] -eq 'default'){
                $start=$true
            }
            if ($start){
                if ($line.Substring($portLoc)){
                    $output+=$line.Substring($portLoc)
                    $found=$true
                }
            }
        } 
        if ($line -match 'sh vlan id 1'){
                $vlan1=$true
        }
  
    } 
    if (!$start) {
        $output+="something broke"
        $found=$true
    }
    if ($found) {$output+=$IP}
}


$output > "$scriptDir\outputs\findings.txt"

