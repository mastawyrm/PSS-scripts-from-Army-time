$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()
$oneIP = ''
$twoIP = ''
$bothIP = ''


foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    $one=$false
    $two=$false
    foreach ($line in $fileContent){
        if ($line -match '^line'){
            if ($line -match '^line con'){$one=$true}
            else {$one=$false}
        }
        if ($one) {
            if ($line -match 'password'){$output+="$line`n"; $two=$true}
        }
    }
    if (!$two){$output+="no password`n"}
    $output+="$IP`n"
}

$list=@()
foreach($line in $output){
    if ($line -match 'password 7'){
        $pass=$line -replace ' password 7 ',''
        if ($list -notcontains $pass){$list+=$pass}
    }
}

#$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
$output > "$scriptDir\outputs\findings.txt"


