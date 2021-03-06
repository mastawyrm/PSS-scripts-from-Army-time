$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''
$defaultRoles = 'network-admin','network-operator','vdc-admin','vdc-operator'



foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    $role=$false
    $RWrole=@()
    $ROrole=@()
    foreach ($line in $fileContent){
        if ($line -notmatch '^role name|^  description|^  rule'){$role=$false}
        if ($role){
            if ($line -match 'permit read-write'){
                $RWrole+=$name
            }
            if ($line.Trim() -match 'permit read$'){
                $ROrole+=$name
            }
        }
        if ($line -match '^role name'){
            $name = $line -replace 'role name ','' 
            $role=$true        
        }       
        if ($line -match '^snmp-server user'){
            $lineSplit=$line.Split() | ? {$_}
            if ($defaultRoles -notcontains $lineSplit[3]){
                if ($RWrole -contains $lineSplit[3]){
                    if ($lineSplit[4] -ne 'auth' -or $lineSplit[7] -ne 'priv'){
                        $output+="$line`n"
                        $found=$true
                    }
                }
            }
        }
        
    } 

    if ($found) {$output+="$IP`n"}
}


$output > "$scriptDir\outputs\findings.txt"

