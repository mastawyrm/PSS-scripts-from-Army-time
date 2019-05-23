$address = "123.234.56.78"
$hex = @()

$address.split('.') | foreach {'{0:x}' -f ($_ -as [int])}
