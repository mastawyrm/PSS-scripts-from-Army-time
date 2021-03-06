#  stores the folder from which the script is run to be used as a "root" folder from there on out
$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# stream functions for use by ssh functions
function ReadStream($stream, $expect){
    $output = ""
    $enc = new-object system.text.asciiEncoding
    $timeout = New-TimeSpan -Minutes 2
    $kickIt = New-TimeSpan -Seconds 20
    $mainSW = [diagnostics.stopwatch]::StartNew()
    
    while ($output.TrimEnd() -notmatch $expect -and $mainSW.Elapsed -lt $timeout){
        while ($stream.DataAvailable){
            $mainSW = [diagnostics.stopwatch]::StartNew()
            $kickSW = [diagnostics.stopwatch]::StartNew()
            write-host "." -NoNewline
            $buffer = new-object system.byte[] 2048
            $read = $stream.Read($buffer,0,2048)
            $output = "$output$($enc.GetString($buffer, 0, $read))"
        } 
        if ($kickSW.Elapsed -gt $kickIt) {
            $kickSW = [diagnostics.stopwatch]::StartNew()
            write-host "Kick"
            $stream.write("`n")
            Start-Sleep -m 100
        }
        Start-Sleep -m 100
    }
    write-host "`n"
    return $output.Split("`n")
}



#  main function to perform commands on cisco devices and return results into 
#  the $output variable which can be defined before the function call
#  this was my first attempt
function docommands($IP,$commands,$cred) {
    if ($IP -match '^#'){return $NULL}
    Import-Module Posh-SSH
    Get-SSHSession | % {$_.sessionid} | ForEach-Object {Remove-SSHSession -SessionId $_}    
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
    Start-Sleep -m 700
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
    
    Get-SSHSession | % {$_.sessionid} | ForEach-Object {Remove-SSHSession -SessionId $_}
   # Remove-SSHSession -SessionId 1
   # Get-SSHSession
}



#  new main function for sending commands and receiving response
function sendcommands($IP,$commands,$cred,$returnName=$false) {
    if ($IP -match '^#'){return $NULL}
    Import-Module Posh-SSH
    $hostname = ''
    $count=0
    while ($count -le 2)    
    {    
        try {    
            $count++
            Get-SSHSession | % {$_.sessionid} | ForEach-Object {Remove-SSHSession -SessionId $_} | Out-Null
            New-SSHSession -ComputerName $IP -Credential $cred -AcceptKey | Out-Host
            $session = Get-SSHSession -Index 0
            $stream = $session.Session.CreateShellStream("dumb", 80, 24, 800, 600, 1024)
            $output = ''
            $firstread = ReadStream -stream $stream -expect ">$|#$"
            $hostname = $firstread[-1].trimend()
            while ("$hostname" -match ">$"){
                $stream.Write("enable`n")
                ReadStream -stream $stream -expect ":$" | Out-Null
                $enablePass = Read-Host -prompt "password for enable:" -AsSecureString
                $ePass=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($enablePass))
                $stream.Write("$ePass`n")
                $firstread = ReadStream -stream $stream -expect ">$|#$"
                $hostname = $firstread[-1].trimend()
            }
            $stream.Write("term length 0`n")
            ReadStream -stream $stream -expect "#$" | Out-Null
            Start-Sleep -m 500
            foreach ($command in $commands){
                $stream.Write("`n$command`n")
                if ($command -match "wr"){
                    $output += ReadStream -stream $stream -expect "Building configuration"
                }
                else {$output += ReadStream -stream $stream -expect "#$"}
            }
            $count = 3
        }
        catch [System.Security.SecurityException]
        {
            write-host "key mismatch on $IP"
            noMisKey -IP $IP

        }
        catch [Renci.SshNet.Common.SshOperationTimeoutException]
        {
            Write-Host "no response from $IP"
		    $IP >> "$scriptDir\IPs\noresponse.txt"
		    return $NULL
            $count = 3
        }
        catch [Renci.SshNet.Common.SshAuthenticationException]
        {
            write-host "wrong password on $IP"
            $count = 3
        }
        finally
        {
            Get-SSHSession | % {$_.sessionid} | ForEach-Object {Remove-SSHSession -SessionId $_} | Out-Null
        }
    }
    if ($returnName){return $output,$hostname} else {return $output}

}




#  simple function to return an IP from a given string as well as the option
#  to convert to binary
Function ExtractValidIPAddress($String,$convert2BIN=$false,$CIDR=$false){
    if ($CIDR -and $convert2BIN){return}
    if ($CIDR){
        $CIDRregex=‘(?<CIDR>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)((\/|_)([1-2][0-9]|3[0-2]|[0-9])))’
        If ($String -Match $CIDRregex) {$out = $Matches.CIDR}
    }
    else{
        $IPregex=‘(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))’
        If ($String -Match $IPregex) {$out = $Matches.Address}
    }
    if ($convert2BIN -and $out){
        $bin = $out.split('.') | foreach {[convert]::ToString($_,2)} 
        $out = ""
        foreach ($octet in $bin){$out+=$octet.padleft(8, '0')}
    }
    return $out
}


#  compare an IP and subnet, returning whether the subnet contains the IP
Function IsTheIPinTheSubnet($address,$ID,$mask){
    $IPbin = ExtractValidIPAddress -String $address -convert2BIN $true
    $IDbin = ExtractValidIPAddress -String $ID -convert2BIN $true
    return ($IPbin.Substring(0,$mask) -eq $IDbin.Substring(0,$mask))
}



#  add IPs from test set to current set only if not already in current set
function testIPs($IPsfortest,$currentIPs){
    $newIPs = @()
    $newIPs = Diff $IPsfortest $currentIPs -PassThru | where {$_.SideIndicator -eq '<='} | Get-Unique
#	$out = @($currentIPs)
#	ForEach ($IPt in $IPsfortest) {
#		$count = 0
#		#write-host "IPt1 $IPt"      
#        ForEach ($IPc in $out) {
#            if ($IPt -eq $IPc) {$count ++}
#			#"IPt $IPt IPc $IPc count $count" >> "$scriptDir\outputs\neighbor\debug.txt"
#            if ($count -ne 0) {
#				#"IPt $IPt IPc $IPc count $count" >> "$scriptDir\outputs\neighbor\debug.txt"
#				break
#			}
#        }
#        if ($count -eq 0) {
#			$out += $IPt
#			$newIPs += $IPt
#			#write-host "Added $IPt"
#		}
#    }
	return $newIPs
}


#  take list of interfaces and create int range strings
function sortInt($interfaces,$command){
    $result=''
    $last=''
    $first=$true
    $count=0
    foreach ($line in $interfaces){
        $lineSplit = $line.split('/')
        if ($line -match '^GigabitEthernet'){$lineSplit[0]=$lineSplit[0] -replace 'GigabitEthernet',''}
        elseif ($line -match '^Gi'){$lineSplit[0]=$lineSplit[0] -replace 'Gi',''}
        elseif ($line -match '^FastEthernet'){$lineSplit[0]=$lineSplit[0] -replace 'FastEthernet',''}
        elseif ($line -match '^Fa'){$lineSplit[0]=$lineSplit[0] -replace 'Fa',''}
        elseif ($line -match '^TenGigabitEthernet'){$lineSplit[0]=$lineSplit[0] -replace 'TenGigabitEthernet',''}
        elseif ($line -match '^Te'){$lineSplit[0]=$lineSplit[0] -replace 'Te',''}
        if($new -or $first){
            if ($new) {$result+="`n"}
            $result+="int range $line"; $new=$false; $first=$false
        }
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
            $result+="`n$command"
            $new=$true
            $count=0
        }
        $lastSplit=$lineSplit
        $last=$line
    }
    if ($candidate){$result+="$candidate"}
    if ($result -notmatch "$command$"){
        $result += "`n$command"
    }
    return $result
}

function findRanges($intList,$command,$nexus = $false){
    $result=''
    $interfaceList=''
    $output=''
    $content = $intList#.split("`n")
    foreach ($line in $content){
            $list=$interfaceList -replace ',$',''
            $result = sortInt -interfaces $list -nexus $nexus
            $interfaceList = ''
            if ($result -ne 'int range '){$output+="$result`n$command`n$IP`n"}
            $result = ''
    }
    return $output
}


#open a prompt for choosing a file, initial directory can be passed or defaults to user's My Documents
function Get-File ($startDir = "$home\Documents"){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $openFile = New-Object system.windows.forms.openFileDialog
    $openFile.initialDirectory = $startDir
    $openFile.filter = "All files (*.*)| *.*"
    $openFile.ShowDialog() | Out-Null
    $openFile.FileName
}

#open a prompt for choosing a folder
function Get-Folder ($startDir = "MyDocuments"){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $folder = New-Object System.Windows.Forms.FolderBrowserDialog
    $folder.RootFolder = $startDir
    $folder.Description = "What"
    $folder.ShowDialog() | Out-Null
    $folder.SelectedPath 
}

#release custom objects

function Release-Ref ($ref) {

([System.Runtime.InteropServices.Marshal]::ReleaseComObject(

[System.__ComObject]$ref) -gt 0)

[System.GC]::Collect()

[System.GC]::WaitForPendingFinalizers()

}


#take a list of IPs and combine them into ranges

function IPrange ($input){
    $sorted = $input | sort | gu
    foreach ($IP in $sorted){
        $octets=@()
        foreach ($thing in $sorted.split('.')){$octets += [int]$thing}
        $i=0
        do {}until ($i -eq 4)
        $lastOctets=$octets
    }
}



# remove old keys from PoshSSH registry

function noMisKey ($IP){
    $item = Get-Item "HKCU:\Software\PoshSSH"
    $item | Remove-ItemProperty -name $IP
}

function loadDialog(){
    [CmdletBinding()]

    Param(

     [Parameter(Mandatory=$True,Position=1)]

     [string]$XamlPath

    )

 

    [xml]$Global:xmlWPF = Get-Content -Path $XamlPath

 

    #Add WPF and Windows Forms assemblies

    try{

     Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,system.windows.forms

    } catch {

     Throw "Failed to load Windows Presentation Framework assemblies."

    }

 

    #Create the XAML reader using a new XML node reader

    $Global:xamGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xmlWPF))

 

    #Create hooks to each named object in the XAML

    $xmlWPF.SelectNodes("//*[@Name]") | %{

     Set-Variable -Name ($_.Name) -Value $xamGUI.FindName($_.Name) -Scope Global

     }
}