$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

[float]$total = 0
$last = 1
for ($i=0; $i -lt 64; $i++){
    Write-Host $total
    $total += ([math]::pow(2,$i))
}

$dollar = $total/100
Write-Host ($dollar)
