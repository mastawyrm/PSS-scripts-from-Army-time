$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = @()
$promptList = @()


foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    foreach ($line in $fileContent){
        if ($line -match 'sh vers'){
            $prompt=$line -replace 'sh vers',''
            break
        }
    }
    if ($promptList -notcontains $prompt){
        $promptList+=$prompt
    }
    else {
        $output+="$prompt $IP"
        Move-Item $filename -Destination "$scriptDir\outputs\shruns\New Folder\$IP.txt" -Force
    }
}

$output > "$scriptDir\outputs\dupehost.txt"

