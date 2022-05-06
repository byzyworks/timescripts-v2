cd $PSScriptRoot

$DATETIME_FORMAT = '%Y/%m/%d %H:%M:%S'
$SLOTS_DIR       = '.\slots'
$LOG             = '.\log.txt'

$startupDatetime = (Get-Date -UFormat $DATETIME_FORMAT)
$startupMessage  = "-------------------------------+`r`nSent     @ $startupDatetime | Time Manager Startup`r`nReceived @ $startupDatetime |`r`n-------------------------------+"

Write-Host $startupMessage

while ($true) {
	$currentId = (Get-Date -UFormat '%s')
	$slots = (Get-Item -Path $SLOTS_DIR\*)
    foreach ($slot in $slots) {
		$slotId = ($slot.Name -split ' ')[0]
        if ($currentId -ge $slot.Name) {
            & $slot
			Remove-Item $slot
        }
    }
	Start-Sleep -Milliseconds 800
}