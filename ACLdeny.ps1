$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''
#$checkline = Get-Content "$scriptDir\outputs\checkline.txt" | Where-Object { $_ -ne '' }



foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $found=$false
    foreach ($line in $fileContent){
        if ($line -match '^ip access-list'){
            $ACL=$line.trim() -replace 'ip access-list ',''
        }
        if ($line -match 'deny'){
            if ($line -notmatch 'log'){
                $output+="$ACL`n$line`n"
                $found=$true
            }
        }        
    } 

    if ($found) {$output+="$IP`n"}
}


$output > "$scriptDir\outputs\findings.txt"

