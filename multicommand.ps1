$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$User=Read-Host -prompt "username:"
$PWord=Read-Host -prompt "password:" -assecurestring
$commands=@()
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $PWord

$file=Get-Content "$scriptDir\multicommands.txt" | Where-Object { $_ -ne '' }

."$scriptDir\functions.ps1"

$commands+="conf t"
foreach ($line in $file){
    $IP = ExtractValidIPAddress -String $line
    if ($line -ne $IP){$IP=''}
    if (!$IP) {$commands+="$line"}
    else {
        $commands+="end`nwr"
        $output = "$scriptDir\outputs\$IP.txt"
        CiscoCommand -IP $IP -commands $commands -cred $cred
        $commands=@()
        $commands+="conf t"
    }
}

