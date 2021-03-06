$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$IPfile=Get-Content "$scriptDir\IPs\NexusIPs.txt" | Where-Object { $_ -ne '' }
$User=Read-Host -prompt "username:"
$pass=Read-Host -prompt "password:" -assecurestring
$commands= 'sh access-list 22'
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $pass

."$scriptDir\functions.ps1"

foreach ($IP in $IPfile){
    $output = "$scriptDir\outputs\access\$IP.txt"
    CiscoCommand -IP $IP -commands $commands -cred $cred
}
$done=$true

