$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()

$currentHost=Get-Content "$scriptDir\outputs\hostnames.txt"| Where-Object { $_ -ne '' }
$currentIP=@()
foreach ($line in $currentHost){
    $IP = ExtractValidIPAddress -String $line
    if ($currentIP -notcontains $IP){$currentIP+=$IP}
}

function pingtest($3rd) {
    for ($4th=0; $4th -le 255; $4th++){
        $IPiteration="10.93.$3rd.$4th"
        if ($currentIP -notcontains $IPiteration){
            if (Test-Connection $IPiteration -count 1 -quiet){
                $output+="$IPiteration"
            }            
        }
    }
}

#pingtest 128
#pingtest 129
for ($i=136; $i -le 140; $i++){
    pingtest $i
}
for ($i=144; $i -le 146; $i++){
    pingtest $i
}
pingtest 152
for ($i=154; $i -le 157; $i++){
    pingtest $i
}




#$oneIP > "$scriptDir\outputs\one.txt"
#$twoIP > "$scriptDir\outputs\two.txt"
#$bothIP > "$scriptDir\outputs\both.txt"
$output > "$scriptDir\outputs\newIPs.txt"


