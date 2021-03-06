$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''


foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    
    $one=$false
    $two=$false
    $trunk=$false
    $native=$false
    $1001=''
    $shut=''
    foreach ($line in $fileContent){
        #$lineSplit=$line.split()
        if ($line -match '^interface'){
            $int=$line
            $one=$true
        }
        if ($one){
            if ($line -match 'switchport mode trunk'){
                $trunk=$true 
            }
            if ($line -match 'native vlan'){
                $native=$true
                if ($line -notmatch '1001$'){
                    $1001=$line
                }
            }
            if ($line -match '^ shutdown'){$shut=$line}
        }
        if ($line -match '^!'){
            $one=$false
            if($trunk -and !$shut){
                if($native){
                    if($1001){$output+="$int`n$1001`n"; $two=$true}
                }
                else {$output+="$int`n switchport trunk native vlan 1001`n"; $two=$true}
            }
            $int=''
            $shut=''
            $trunk=$false
            $native=$false
        }
    } 
    if ($two) {$output+="$IP`n`n"}
}



#$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
$output > "$scriptDir\outputs\findings.txt"

