$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''
$check = '99','1000','routed','trunk'
$trunkList=''
$accessList=''
$nothingList=''
$fileCount=0


foreach ($filename in $workingFiles) {
    $fileCount++
    $perc=100*$fileCount/$workingFiles.length
    Write-Progress "Files done" "% complete" -PercentComplete $perc
    
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    if ($IP -eq '10.93.128.166'){
    $hello=$true}
    $search=$false
    $prompt=''
    $statusIDx=''
    $found=$false
    $intConfig=$false
    $interfaces = @()
    $trunks = ''
    $accessPorts = ''
    $nothingPorts = ''
    $trunk=$false
    $native=$false
    $shutdown=$false
    $access=$false
    $1000=$false
    #$lineCount=0
    #$lineTotal = $fileContent.Length
    foreach ($line in $fileContent){
        #$lineCount++
        #Write-Progress -id 1 "Lines done" "Percent file" -PercentComplete (100*$lineCount/$lineTotal)
        $count++        
        if ($line -match '#sh vers' -or $line -match '>sh vers'){
            $prompt=$line -replace 'sh vers',''
        }
        if ($search){
            if ($line -match $prompt){
                if (!$found){break}
                $search=$false
            }
        }
        if ($line -match '^Port' -and $line -match 'Status'){
            $statusIDx = $line.IndexOf('Status')
            $search=$true
        }
        if ($search){
            $statusSplit = $line.Substring($statusIDx).split() | ? {$_}
            $lineSplit = $line.split() | ? {$_}
            if ($line -match '^Gi'){$interface=$lineSplit[0] -replace 'Gi','GigabitEthernet'}
            elseif ($line -match '^Te'){$interface=$lineSplit[0] -replace 'Te','TenGigabitEthernet'}
            elseif ($line -match '^Fa'){$interface=$lineSplit[0] -replace 'Fa','FastEthernet'}
            if ($statusSplit[1] -eq '1'){
                $found=$true
                $interfaces+=$interface
            }
            elseif ($statusSplit[0] -eq 'disabled'){
                if ($check -notcontains $statusSplit[1]){
                    $found=$true
                    $interfaces+=$interface
                }
            }
        }
        if ($found){
            if ($line -match '^interface'){
                $lineSplit=$line.Split() | ? {$_}
                if ($interfaces -contains $lineSplit[1]){
                    $intConfig=$true
                    $count=0
                }
            }
            if ($intConfig){
                if ($line -match 'shutdown'){
                    $shutdown=$true
                }
                if ($line -match 'switchport mode trunk'){
                    $trunk=$true
                }
                if ($line -match 'switchport trunk native vlan 1001'){
                    $native=$true
                }
                if ($line -match 'switchport mode access'){
                    $access=$true
                }
                if ($line -match 'switchport access vlan 1000'){
                    $1000=$true
                }
                if ($line -match '^!'){
                    $intConfig=$false
                    if ($count -eq 1){
                        $nothingPorts+=$lineSplit[1]+"`n"
                    }
                    if ($shutdown){
                        if ($trunk -and !$native) {$trunks+=$lineSplit[1]+"`n"}
                        if ($access -and !$1000){$accessPorts+=$lineSplit[1]+"`n"}
                    }
                    $trunk=$false
                    $native=$false
                    $shutdown=$false
                    $access=$false
                    $1000=$false
                }
            }
        }
    }
    if ($trunks){
        $trunkList+="$trunks$IP`n"
    }
    if ($accessPorts){
        $accessList+="$accessPorts$IP`n"
    }
    if ($nothingPorts){
        $nothingList+="$nothingPorts$IP`n"
    }
}

$accessRanges = findRanges -intList $accessList -command "switchport access vlan 1000"
$trunkRanges = findRanges -intList $trunkList -command "switchport trunk native vlan 1001"
$nothingRanges = findRanges -intList $nothingList -command "shutdown`nswitchport access vlan 1000"

$accessRanges > "$scriptDir\outputs\accessRanges.txt"
$trunkRanges > "$scriptDir\outputs\trunkRanges.txt"
$nothingRanges > "$scriptDir\outputs\nothingRanges.txt"

