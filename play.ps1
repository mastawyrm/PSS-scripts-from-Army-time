#  stores the folder from which the script is run to be used as a "root" folder from there on out
$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$blah = @()
$blah += Get-ChildItem $scriptDir -Filter "*.ps1" | copy $_.FullName $scriptDir/test/$_