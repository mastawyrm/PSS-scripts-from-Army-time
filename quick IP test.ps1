."C:\Users\ryan.m.hard.ctr\Documents\Cisco_batch\functions.ps1"

$start = @(Get-Content "C:\Users\ryan.m.hard.ctr\Documents\Cisco_batch\IPs\all_IPs_2015.05.19.txt" | Where-Object { $_ -ne '' })
$remove = @(Get-Content "C:\Users\ryan.m.hard.ctr\Documents\Cisco_batch\IPs\NexusIPs.txt" | Where-Object { $_ -ne '' })
$keep = "C:\Users\ryan.m.hard.ctr\Documents\Cisco_batch\IPs\CatIPs.txt"


$newIPs = testIPs -IPsfortest $start -currentIPs $remove

$newIPs >> $keep

