function docommands($IP,$commands,$cred) {
    Import-Module Posh-SSH
    
    New-SSHSession -ComputerName $IP -Credential $cred -AcceptKey
    $session = Get-SSHSession -Index 0
    $stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 5000)
    Start-Sleep -m 200
    $stream.Write("term length 0`n")
    Start-Sleep -m 500
    $stream.Read() > $null
    $stream.Write("`n")
    Start-Sleep -m 50
    $promptlen = $stream.Length
    $stream.Read() > $null
    Write-Host "Prompt size: $promptlen"
    foreach ($command in $commands){
        Start-Sleep 1
        $stream.Write("`n$command`n")
        Start-Sleep -m 500
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
                Start-Sleep -m 200
                $diff = $stream.Length - $length;
                Write-Host "Difference: $diff";
            } while ($diff -ne $promptlen)
            $count = 0
            Do {
                if ($stream.Length -ne 0) {$stream.Read() >> $output};
                Start-Sleep -m 100;
                $length = $stream.Length;
                Write-Host "$length $count"
                if ($length -eq 0) {$count++}
                if ($length -gt 0) {$count = 0}
            } while ($count -lt 5)
        }
    }
    Remove-SSHSession -SessionId 0
   # Remove-SSHSession -SessionId 1
   # Get-SSHSession
    
}

