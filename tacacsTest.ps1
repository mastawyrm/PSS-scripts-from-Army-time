$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$User="ryan.m.hard.ctr.nw"
$PWord=ConvertTo-SecureString –String "rEdstOnE1!" -AsPlainText -Force
$commands=@()
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $PWord

$file=Get-Content "$scriptDir\outputs\one.txt" | Where-Object { $_ -ne '' }

."$scriptDir\functions.ps1"

$commands+="configure terminal`n"
foreach ($line in $file){
    $IP = ExtractValidIPAddress -String $line
    $commands+="end`n"
    $output = "$scriptDir\outputs\$IP.txt"
    if ($IP){docommands -IP $IP -commands $commands -cred $cred}
    $commands="configure terminal`n"
}

