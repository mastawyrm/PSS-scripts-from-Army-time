$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''
$fileCount=0
$trunkList=''
#$checkline = Get-Content "$scriptDir\outputs\checkline.txt" | Where-Object { $_ -ne '' }



foreach ($filename in $workingFiles) {
    $fileCount+=100
    Write-Progress "Files done" "Percent" -PercentComplete ($fileCount/$workingFiles.Length)
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    #$lineCount=0
    $interfaces=''
    foreach ($line in $fileContent){
        #$lineCount+=100
        #Write-Progress -Id 1 "Lines done" "Percent of $IP" -PercentComplete ($lineCount/$fileContent.length)
        if ($line -match '^interface'){
            $lineSplit = $line.Split() | ? {$_}
        }
        if ($line -match 'native vlan'){
            if ($line -notmatch '1001'){
                $interfaces+=$lineSplit[1]+"`n"
                $found=$true
            }
        }
        
    }

    if ($interfaces) {$trunklist+="$interfaces$IP`n"}
}



$trunkRanges = findRanges -intList $trunkList -command "switchport trunk native vlan 1001" -nexus $true

$trunkRanges > "$scriptDir\outputs\trunkRanges.txt"


