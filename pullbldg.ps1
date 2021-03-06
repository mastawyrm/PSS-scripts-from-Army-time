$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$hostnames = Get-Content "$scriptDir\hostnames.txt" | Where-Object { $_ -ne '' }
$output = @()

foreach ($line in $hostnames){
    $parts=$line.split('-')
    $bldg=$parts[3]
    $output+=$bldg
}


$output > "$scriptDir\outputs\buildings.txt"

