$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$IPfile=Get-Content "$scriptDir\IPs\leftover.txt" | Where-Object { $_ -ne '' }
$User="ryan.m.hard.ctr.nw"
$pass=Read-Host -prompt "password:" -assecurestring
$commands= Get-Content "$scriptDir\commands.txt" | Where-Object { $_ -ne '' }
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $pass

."$scriptDir\functions.ps1"

foreach ($IP in $IPfile){
    $output = "$scriptDir\outputs\$IP.txt"
    docommands -IP $IP -commands $commands -cred $cred
}
$done=$true

