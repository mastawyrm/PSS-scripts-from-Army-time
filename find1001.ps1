$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$loopbacks = Get-Content "$scriptDir\outputs\loopbacks.txt" | Where-Object { $_ -ne '' }
$output = ''
$oneIP = ''
$twoIP = ''
$bothIP = ''
$check = Get-Content "$scriptDir\IPs\1001s.txt" | Where-Object { $_ -ne '' }
#$checkline = Get-Content "$scriptDir\outputs\checkline.txt" | Where-Object { $_ -ne '' }



foreach ($filename in $workingFiles) {
    
    $IP = ExtractValidIPAddress -String $filename
    $one=$false
    $authorize=$false
    $access=$false
    if ($check -contains $IP){
        $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
        foreach ($line in $fileContent){
            $lineSplit=$line.split()
            if ($line -match '^interface'){
				$int=$lineSplit[-1]
				$one=$true
            }
            if ($one){
                if ($line -match 'authorize vlan 1001$'){$authorize=$true}
                if ($line -match 'access vlan 1001$'){$access=$true}
                if ($line -match '^!'){
                    if ($authorize){$oneIP+="$int`n"}
                    if ($access){$twoIP+="$int`n"}
                    $int=''
                    $one=$false
                    $authorize=$false
                    $access=$false
			    }
            }

        }
        $oneIP+="$IP`n"
        $twoIP+="$IP`n"
    }
}



$oneIP > "$scriptDir\outputs\authorize.txt"
$twoIP > "$scriptDir\outputs\access.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
#$output > "$scriptDir\outputs\intlist.txt"

