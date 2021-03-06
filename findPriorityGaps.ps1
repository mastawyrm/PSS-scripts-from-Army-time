$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\access"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$current = @()
$dupes = @()
$gaps = @()

$fileContent = Get-Content "$scriptDir\outputs\current_SSL_users_6Jul2015.txt" | Where-Object { $_ -ne '' }
$IP = ExtractValidIPAddress -String $filename


foreach ($line in $fileContent){        
    $number=''
    $lineSplit=$line.split() | ? {$_}
    $number=$lineSplit[2]
    if ($current -notcontains $number){$current+=$number}
    else {$dupes+=$number}
}

for ($i=39; $i -lt 5700; $i++){
    if ($current -notcontains $i){$gaps+=$i}
}

$dupes > "$scriptDir\outputs\duplicate_priority.txt"
$gaps > "$scriptDir\outputs\priority_gaps.txt"


