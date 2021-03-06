$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$IPfile=Get-Content "$scriptDir\IPs\NexusIPs.txt" | Where-Object { $_ -ne '' }
$User="ryan.m.hard.ctr.nw"
$PWord=ConvertTo-SecureString –String "rEdstOnE1!" -AsPlainText -Force
$commands= 'sh callhome'
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $PWord

."$scriptDir\functions.ps1"

foreach ($IP in $IPfile){
    $output = "$scriptDir\outputs\$IP.txt"
    docommands -IP $IP -commands $commands -cred $cred
}
$done=$true

