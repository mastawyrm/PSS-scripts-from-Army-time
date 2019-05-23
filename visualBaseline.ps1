$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
."$scriptDir\functions.ps1"

loadDialog -XamlPath "$scriptDir\Forms\mainForm.xaml"

# textbox for entering output path
$outputPathBox.Text = "$scriptDir\outputs"

# button to browse for folder to place output files
$outputButton.add_click({
    $tempPath = Get-Folder
    if ($tempPath){$outputPathBox.Text = $tempPath}
})

# textbox for entering commands
$commandBox.Add_GotFocus({
    if ($commandBox.Text -match "enter commands..."){
        $commandBox.Text = $commandBox.Text -replace "enter commands...",""
    }
})
$commandBox.Add_LostFocus({
    if ($commandBox.Text.Trim() -eq ""){
        $commandBox.Text = "enter commands..."
    }
})

# textbox for entering target IPs
$IPbox.Add_GotFocus({
    if ($IPbox.Text -match "enter IPs..."){
        $IPbox.Text = $IPbox.Text -replace "enter IPs...",""
    }
})
$IPbox.Add_LostFocus({
    if ($IPbox.Text.Trim() -eq ""){
        $IPbox.Text = "enter IPs..."
    }
})

# button for adding a list of IPs to the IP box
$browseButton.add_Click({
    $IPlist = ''
    Get-Content (Get-File -startDir "$scriptDir\IPs\") | ForEach-Object {
        $IPlist += ExtractValidIPAddress -String $_
        $IPlist += "`n"
    }
    $IPbox.Text = $IPlist
})

# go button starts the loop of connections
$gobutton.add_Click({
    $cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $usernameBox.Text, $passwordBox.SecurePassword
    $outputPath = $outputPathBox.Text
    $IPbox.Text.Split("`n") | where {$_.trim() -ne ''} | ForEach-Object {
        $IP = ExtractValidIPAddress -String $_ 
        $commands = $commandBox.Text.Split("`n") | where {$_.trim() -ne ''}
        $output = ''
        $output = sendcommands -IP $IP -commands $commandBox.Text.Split("`n") -cred $cred
        md "$outputPath" -Force
        if ($output) {$output > "$outputPath\$IP.txt"}
    }
    Write-Host "Done"
})

# this goes at the bottom to invoke display
$xamGUI.ShowDialog() | Out-Null