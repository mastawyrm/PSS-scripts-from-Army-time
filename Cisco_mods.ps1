#  stores the folder from which the script is run to be used as a "root" folder from there on out
$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# stream functions for use by ssh functions
function ReadStream($reader){
    start-sleep -m 500
    $datas=$reader.ReadLine()
    Write-host "Reading" -NoNewline
    $count=0

    while ($datas -ne $null){
        while ($stream.Length -ne 0){
            start-sleep -m 10
            $datas=$reader.Readline()
            $datas
            $count++
            if ($count%10 -eq 0){
                Write-Host "!" -NoNewline
            }
        }
        Start-Sleep -m 100
        $datas=$reader.ReadLine()
        $datas
        $count++
        if ($count%10 -eq 0){
            Write-Host "." -NoNewline
        }
    }
    Write-Host "`n"
}

function WriteStream($cmd, $writer, $stream){
    $writer.Write($cmd)
    $count=0
    $origpos = $Host.UI.RawUI.CursorPosition
    while ($stream.Length -eq 0){
        start-sleep -m 10
        $Host.UI.RawUI.CursorPosition = $origpos
        $elapsed = $count/10
        write-host "Wait for response: $elapsed sec"
        $count++
    }
}

function waitATick($stream){
    $count=0
    $origpos = $Host.UI.RawUI.CursorPosition
    while ($stream.Length -eq 0){
        start-sleep -m 10
        $Host.UI.RawUI.CursorPosition = $origpos
        $elapsed = $count/10
        write-host "Wait for response: $elapsed sec"
        $count++
    }
}


#  main function to perform commands on cisco devices and return results into 
#  the $output variable which can be defined before the function call
function docommands($IP,$commands,$cred) {
    if ($IP -match '^#'){return $NULL}
    Import-Module Posh-SSH
    New-SSHSession -ComputerName $IP -Credential $cred -AcceptKey
    if (-not (Get-SSHSession)) {
		Write-Host "no response"
		$IP >> "$scriptDir\IPs\noresponse.txt"
		return $NULL
		}
	$lastline=''
    $session = Get-SSHSession -Index 0
    $stream = $session.Session.CreateShellStream("dumb", 80, 24, 800, 600, 1024)
    Start-Sleep -m 500
    $stream.Write("term length 0`n")
    Start-Sleep -m 500
    $stream.Read() > $null
    $stream.Write("`n")
    Start-Sleep -m 600
    $promptlen1 = $stream.Length
    $stream.Read() > $null
    Write-Host "Prompt size: $promptlen1"
	$conf = $false
	$promptlen = $promptlen1
    $null > $output
    foreach ($command in $commands){
		Start-Sleep 1
        $stream.Write("`n$command`n")
        Start-Sleep -m 500
		if ($command -match 'conf t') {$conf = $true}
		if ($command -match 'end') {$conf = $false; Start-Sleep -m 500}
		if ($conf) {
            Start-Sleep -m 750
			$stream.Read() >> $output
			$stream.Write("`n")
			Start-Sleep -m 200
			$promptlen = $stream.Length
			Write-Host "Conf Prompt size: $promptlen"
		} else {$promptlen = $promptlen1; Write-Host "End Prompt size: $promptlen1"}
        if ($stream.Length -lt $promptlen) {$stream.Read() >> $output}
        $count=0
        Do {
            Write-Host "Stream: "$stream.Length "Count: $count";
            Start-Sleep 1;
            $count++;
        } until ($stream.Length -gt 0 -or $count -eq 30)
  
        if ($count -lt 30) {
            Do {
                $length = $stream.Length;
                $stream.Write("`n");
                Start-Sleep -m 500
                $diff = $stream.Length - $length;
                Write-Host "Difference: $diff";
            } while ($diff -ne $promptlen)
            $count = 0
            Do {
                if ($stream.Length -ne 0) {$stream.Read() >> $output};
                Start-Sleep -m 100;
                $length = $stream.Length;
                #Write-Host "$length $count"
                if ($length -eq 0) {$count++}
                if ($length -gt 0) {$count = 0}
            } while ($count -lt 3)
        }
    }
    
    Remove-SSHSession -SessionId 0
   # Remove-SSHSession -SessionId 1
   # Get-SSHSession
}


# Brocade specific connections
function BrocadeCommand($IP,$commands,$cred) {
    if ($IP -match '^#'){return $NULL}
    Import-Module Posh-SSH
    New-SSHSession -ComputerName $IP -Credential $cred -AcceptKey
    if (-not (Get-SSHSession)) {
		Write-Host "no response"
		$IP >> "$scriptDir\IPs\noresponse.txt"
		return $NULL
    }
    $session = Get-SSHSession -Index 0
    $stream = $session.Session.CreateShellStream("dumb", 80, 24, 800, 600, 1024)
    $reader = new-object System.IO.StreamReader($stream)
    $writer = new-object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    waitATick $stream
    ReadStream $reader >> $output
    WriteStream -cmd "`nskip-page-display`n" -writer $writer -stream $stream
    ReadStream $reader >> $output
    
    foreach ($command in $commands){
		write-host $command
        WriteStream -cmd "`n$command`n" -writer $writer -stream $stream
        ReadStream $reader >> $output
    }
    $stream.Dispose()
    Remove-SSHSession -SessionId 0
}



# new cisco command
function CiscoCommand($IP,$commands,$cred) {
    if ($IP -match '^#'){return $NULL}
    Import-Module Posh-SSH
    New-SSHSession -ComputerName $IP -Credential $cred -AcceptKey
    if (-not (Get-SSHSession)) {
		Write-Host "no response"
		$IP >> "$scriptDir\IPs\noresponse.txt"
		return $NULL
    }
    $session = Get-SSHSession -Index 0
    $stream = $session.Session.CreateShellStream("dumb", 80, 24, 800, 600, 1024)
    $reader = new-object System.IO.StreamReader($stream)
    $writer = new-object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    waitATick $stream
    ReadStream $reader >> $output
    WriteStream -cmd "`nterm length 0`n" -writer $writer -stream $stream
    ReadStream $reader >> $output
    
    foreach ($command in $commands){
		write-host $command
        WriteStream -cmd "`n$command`n" -writer $writer -stream $stream
        waitATick $stream
        ReadStream $reader >> $output
    }
    Remove-SSHSession -SessionId 0
}



#  simple function to return an IP from a given string
Function ExtractValidIPAddress($String){
    $IPregex=‘(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))’
    If ($String -Match $IPregex) {$Matches.Address}
}


#  use cdp to find neighbors of each device in $IPfile
function searchNeighbor($IPfile,$workingdir,$cred) {
    $commands = Get-Content "$scriptDir\neighborcommands.txt"
    foreach ($IP in $IPfile){       
        $output = "$workingdir\$IP.txt"
        docommands -IP $IP -commands $commands -cred $cred
    }
}


#  add IPs from test set to current set only if not already in current set
function testIPs($IPsfortest,$currentIPs){
    $newIPs = @()
	$out = @($currentIPs)
	ForEach ($IPt in $IPsfortest) {
		$count = 0
		#write-host "IPt1 $IPt"
        ForEach ($IPc in $out) {
            if ($IPt -eq $IPc) {$count ++}
			#"IPt $IPt IPc $IPc count $count" >> "$scriptDir\outputs\neighbor\debug.txt"
            if ($count -ne 0) {
				#"IPt $IPt IPc $IPc count $count" >> "$scriptDir\outputs\neighbor\debug.txt"
				break
			}
        }
        if ($count -eq 0) {
			$out += $IPt
			$newIPs += $IPt
			#write-host "Added $IPt"
		}
    }
	return $newIPs
}


#  take list of interfaces and create int range strings
function sortInt($interfaces){
    $result=''
    $last=''
    $new=$true
    $count=0
    foreach ($line in $interfaces.split(',')){
        $lineSplit = $line.split('/')
        if ($line -match '^GigabitEthernet'){$lineSplit[0]=$lineSplit[0] -replace 'GigabitEthernet',''}
        elseif ($line -match '^FastEthernet'){$lineSplit[0]=$lineSplit[0] -replace 'FastEthernet',''}
        elseif ($line -match '^TenGigabitEthernet'){$lineSplit[0]=$lineSplit[0] -replace 'TenGigabitEthernet',''}
        if($new){$result+="int range $line"; $new=$false}
        else{ 
            $pass=$true
            for ($i=0; $i -lt $lineSplit.count - 1; $i++){
                if ($lineSplit[$i] -ne $lastSplit[$i]){
                    $pass=$false
                    $result+="$candidate,$line"
                    $count++
                    $candidate=''
                    break
                }
            }
            if($pass){
                if ($lineSplit[$i]-1 -eq $lastSplit[$i]){$candidate='-'+$lineSplit[$i]}
                else {$result+="$candidate,$line"; $count++; $candidate=''}
            }
        }
        if (!$nexus -and $count -ge 4){
            $result+="`n$command`n"
            $new=$true
            $count=0
        }
        $lastSplit=$lineSplit
        $last=$line
    }
    if ($candidate){$result+="$candidate"}
    return $result
}

function findRanges($intList,$command,$nexus = $false){
    $result=''
    $interfaceList=''
    $output=''
    $content = $intList.split("`n")
    foreach ($line in $content){
        $IP = ExtractValidIPAddress -String $line
        if (!$IP){$interfaceList+="$line,"}
        if ($IP){
            $list=$interfaceList -replace ',$',''
            $result = sortInt -interfaces $list -nexus $nexus
            $interfaceList = ''
            if ($result -ne 'int range '){$output+="$result`n$command`n$IP`n"}
            $result = ''
        }
    }
    return $output
}


