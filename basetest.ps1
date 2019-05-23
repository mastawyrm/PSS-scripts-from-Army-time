$IPfile=Get-Content -filter "\n" "C:\Users\ryan.m.hard.ctr\Documents\Cisco_batch\IPs\one.txt" | Where-Object { $_ -ne '' }
$commands= Get-Content "C:\Users\ryan.m.hard.ctr\Documents\Cisco_batch\commands.txt"
."C:\Users\ryan.m.hard.ctr\Documents\Cisco_batch\credfile.ps1"
$PWord=ConvertTo-SecureString –String "$Pass" -AsPlainText -Force
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $PWord

."C:\Users\ryan.m.hard.ctr\Documents\Cisco_batch\test.ps1"

foreach ($IP in $IPfile){
    $output = "C:\Users\ryan.m.hard.ctr\Documents\Cisco_batch\outputs\$IP.txt"
    docommands -IP $IP -commands $commands -cred $cred
}


