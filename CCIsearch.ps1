$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"


$output = ''
#$checkline = Get-Content "$scriptDir\outputs\checkline.txt" | Where-Object { $_ -ne '' }

$relevantFile = "$scriptDir\small\relevantCCIs.txt"
$relevantContent = Get-Content $relevantFile | Where-Object { $_ -ne '' }
$CCIlist = "$scriptDir\small\CCI_list_files\sheet001.htm"
$CCI = ''
$found=$false
$candidateCCI=''
Measure-Command { Get-Content $CCIlist | Where-Object { $_ -match "CCI-|technical" } | 
    foreach-object {
            $lineSplit = $_.Split("<|>")
            if ($_ -match "CCI" ) {$CCI = $lineSplit[2]}
            else {
                $tech = $lineSplit[2]
            }
            if ($found) {
                if ($tech){$output+="$candidateCCI $tech`n"; $tech=''}
                $found=$false
            }
            if ($relevantContent -contains $CCI) {
                $found=$true
                $candidateCCI="$CCI"
                $CCI=''
            }
#        }
    }
}
$output > "$scriptDir\small\findings.txt"

