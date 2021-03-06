$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()


foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $vlan=$false
    $vlan1=$false
    $ports=''
    $found=$false
    $ints=@()
    $trunk=$false
    $shut=$false
    foreach ($line in $fileContent){
        if ($line -match 'sh vers'){
            $prompt=$line -replace 'sh vers',''
        }
        if ($line -match '^VLAN' -and $line -match 'Ports'){
            $portIDx=$line.IndexOf('Ports')
            $vlan=$true
        }
        if ($line -match 'Type' -and $line -match 'MTU'){
            $vlan=$false
            $vlan1=$false
        }
        if ($vlan){
            if ($line -match '^1'){$vlan1=$true}
            if ($vlan1){
                $ports=$line.Substring($portIDx)
                if ($ports){
                    $portSplit=$ports.split(', ') | ? {$_}
                    foreach ($thing in $portSplit){
                    $ints+=$thing}
                    $convert=$true
                    $ports=''
                }
            }
        }
        $count=0
        if (!$vlan1 -and $convert){
            foreach ($int in $ints){
                if ($int -match '^Gi'){$ints[$count]=$int -replace 'Gi','GigabitEthernet'}
                elseif ($int -match '^Te'){$ints[$count]=$int -replace 'Te','TenGigabitEthernet'}
                elseif ($int -match '^Fa'){$ints[$count]=$int -replace 'Fa','FastEthernet'}
                $count++
            $convert=$false
            }
        }
        if ($ints){
            if ($line -match '^interface'){
                $lineSplit=$line.Split() | ? {$_}
                $intName=$lineSplit[1]
                if ($ints -contains $intName){
                    $intConfig=$true
                    $count=0
                }
            }
            
            if ($intConfig){
                if ($line -match 'switchport mode trunk'){
                    $trunk=$true
                }
                if ($line -match 'switchport trunk allowed'){
                    if ($line -notmatch 'vlan 2-999,1200-4093'){$allowed=$line}
                }
                if ($line -match 'shutdown'){
                    $shut=$true
                }
            }
            if ($line -match '^!'){
                if ($allowed -and $trunk -and !$shut){
                    $output+="$allowed $intName"
                    $found=$true
                }
                $intConfig=$false
                $trunk=$false
                $allowed=''
                $shut=$false
            }
        }
    }
    if ($found){$output+=$IP}
}



#$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
$output > "$scriptDir\outputs\findings.txt"

