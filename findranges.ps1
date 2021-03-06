$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$fileContent = Get-Content "$scriptDir\outputs\authorize.txt" | Where-Object { $_ -ne '' }

function sortInt($interfaces){
    $result=''
    $last=''
    $new=$true
    $count=0
    foreach ($line in $interfaces.split(',')){
        $lineSplit = $line.split('/')
        if ($line -match '^GigabitEthernet'){$lineSplit[0]=$lineSplit[0] -replace 'GigabitEthernet',''}
        elseif ($line -match '^FastEthernet'){$lineSplit[0]=$lineSplit[0] -replace 'FastEthernet',''}
        elseif ($line -match '^TenGigabitEthernet'){$lineSplit[0]=$lineSplit[0] -replace 'TenGigabitEthernet',''}
        if($new){$result+="int range $line"; $new=$false}
        else{ 
            $pass=$true
            for ($i=0; $i -lt $lineSplit.count - 1; $i++){
                if ($lineSplit[$i] -ne $lastSplit[$i]){
                    $pass=$false
                    $result+="$candidate,$line"
                    $count++
                    $candidate=''
                    break
                }
            }
            if($pass){
                if ($lineSplit[$i]-1 -eq $lastSplit[$i]){$candidate='-'+$lineSplit[$i]}
                else {$result+="$candidate,$line"; $count++; $candidate=''}
            }
        }
        if ($count -ge 4){
            $result+="`n"
            $new=$true
            $count=0
        }
        $lastSplit=$lineSplit
        $last=$line
    }
    return $result
}

$result=''
$interfaceList=''
$output=''
foreach ($line in $fileContent){
    $IP = ExtractValidIPAddress -String $line
    if (!$IP){$interfaceList+="$line,"}
    if ($IP){
        $list=$interfaceList -replace ',$',''
        $result = sortInt -interfaces $list
        $interfaceList = ''
        if ($result -ne 'int range '){$output+="$result`n$IP`n"}
        $result = ''
    }
}

$output > "$scriptDir\outputs\intRange.txt"

