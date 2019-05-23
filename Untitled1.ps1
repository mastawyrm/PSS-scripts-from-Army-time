$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$output = "$scriptDir\NSM.exe"

if ($LastExitCode -ne 0)
{
    echo "ERROR: "
    echo $output
    return
}