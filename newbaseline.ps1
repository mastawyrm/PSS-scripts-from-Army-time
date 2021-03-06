$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"
if (!$User){ $User=Read-Host -prompt "Username:" }
if (!$pass){ $pass=Read-Host -prompt "password:" -assecurestring }
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $pass

$IPs = @()
$hostname = @()
$type = @()
$version = @()

$IPfile = Get-File -startDir "$scriptDir\IPs\"

$selectedType = 'any' # options are 'NX-OS' 'IOS' or 'any'

Get-Content $IPfile | ForEach-Object {
    $lineSplit = $_.split(',')
    if ($lineSplit[2] -eq $selectedType -or $selectedType -eq 'any'){
        $IPs += ExtractValidIPAddress -String $_
        $hostname += $lineSplit[1]
        $type += $lineSplit[2]
        $version += $lineSplit[3]
    }
}
$commands = Get-Content "$scriptDir\commands.txt" | Where-Object { $_ -ne '' }


foreach ($IP in $IPs){
    
    $index = $IPs.IndexOf($IP)
    $output = ''
    $output = sendcommands -IP $IP -commands $commands -cred $cred
    if ($output) {$output > "$scriptDir\outputs\$IP.txt"}
}
$done=$true

