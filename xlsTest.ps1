$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# ."$scriptDir\functions.ps1"

#  create excel stuff
$xl = New-Object -COM "Excel.Application"
$xl.Visible = $false
$xl.SheetsInNewWorkbook = 1

#  open file
$wb = $xl.Workbooks.Open("$scriptDir\rule_explosion\nsstc-fw-pri.xlsx")
$outputWB = $xl.workbooks.add()

#  assign variables for worksheets
$policyWS = $wb.sheets.Item(1)
$addressGroupWS = $wb.sheets.Item(3)

#  get IPs from user
$IPs = (Read-Host "enter IPs separated by comma:").Split(',')


foreach ($IP in $IPs) {
    $index = $IPs.indexof($IP) + 1
    $outputWB.Sheets.item(1).name = "$IP"
    for ($i = 1; $i -le $addressGroupWS.UsedRange.Rows.Count; $i++){
        $currentCell = $addressGroupWS.Cells.Item($i, 5).text
        if ($currentCell -match $IP){
            Write-Host $addressGroupWS.Cells.Item($i, 4).text
        }
    }
    if($index -lt $IPs.count){
        $outputWB.sheets.Add() > $null
    }
}


#$policyWS.Cells.Item(2,2).text



#  save and cleanup

$outputWB.saveas("C:\Users\rhard\Documents\scripts\rule_explosion\output.xlsx")

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($currentsheet) > $null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($policyWS) > $null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($addressGroupWS) > $null
$wb.close()
$outputWB.Close()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) > $null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($outputWB) > $null
$xl.quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl) > $null