$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

$workingDir = "$scriptDir\outputs\nexus_shruns"
$workingFiles = Get-ChildItem $workingdir | Where {!$_.PSIsContainer} | % { $_.Fullname }
$output = ''
$checkline = Get-Content "$scriptDir\outputs\checkline.txt" | Where-Object { $_ -ne '' }



foreach ($filename in $workingFiles) {
    $fileContent = Get-Content $filename | Where-Object { $_ -ne '' }
    $IP = ExtractValidIPAddress -String $filename
    $61=$false
    $hostname=''
    $found=$false
    $count=0
    foreach ($line in $fileContent){
        if ($line -match '# sh vers'){
            $lineSplit = $line.split('#')
            $hostname=$lineSplit[0]
        }
        if ($line -match '> sh vers'){
            $lineSplit = $line.split('>')
            $hostname=$lineSplit[0]
        }
        if ($line -notmatch '^  [0-9]'){
            $ACL=$false
        }
        if ($ACL){
            $rule=$line.trim() -replace '^[0-9][0-9] |^[0-9][0-9][0-9] ',''
            if ($checkline -notcontains $rule){
                $output+="$rule`n"
                $found=$true
            }else {$count++}
        }
        if ($line -match '^ip access-list 22'){
            $ACL=$true
        }        
    } 
    if ($count -ne 8){
        $output+="count is $count`n"
        $found=$true
    }
    if ($found) {$output+="$IP`n"}
}


$output > "$scriptDir\outputs\findings.txt"

