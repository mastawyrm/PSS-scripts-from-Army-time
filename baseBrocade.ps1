$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$IPfile=Get-Content "$scriptDir\IPs\legacyBrocade.txt" | Where-Object { $_ -ne '' }
$User="ryan.m.hard.ctr.nw"
$pass=Read-Host -prompt "password:" -assecurestring
$commands= Get-Content "$scriptDir\commands.txt" | Where-Object { $_ -ne '' }
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $pass

."$scriptDir\functions.ps1"

foreach ($IP in $IPfile){
    $output = "$scriptDir\outputs\$IP.txt"
    BrocadeCommand -IP $IP -commands $commands -cred $cred
}

# If running in the console, wait for input before closing.
if ($Host.Name -eq "ConsoleHost")
{
    Read-Host -Prompt “Press Enter to exit”
}


Measure-Command{
    $job = start-job {
                for ($i=0; $i -lt 50; $i++){
                    Start-Sleep -m 100
                }
            }
    Wait-Job $job -Timeout 2
}

