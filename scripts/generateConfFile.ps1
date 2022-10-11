$slotsFileName = "scripts\resources\confSlots.txt"
$eventsFileName = "scripts\resources\confEvents.txt"
$methodsFileName = "scripts\resources\confMethods.txt"
$outputFileName = "Elevator.conf"
$commaSpace = ", "

Get-Content $slotsFileName | Out-File -FilePath $outputFileName
$commaSpace | Out-File -FilePath $outputFileName -Append

$startHandlers = "`"handlers`":["




loop all files



$keyNum = 1  # iterate up for each one ++

$slotKeyNum = 1   # == enum value matching the slot in the slot file

$funcName = "test()"     # name of file
$argumentValue = ""         # if file name has argument   looks like {"value": "forward"}
$code = " -- test code --"  # content of file

$rowString = [string]::Format("{`"key`": `"{0}`", `"filter`": {`"slotKey`": `"{1}`", `"signature`": `"{2}`", `"args`": [{3}]}, `"code`": `"{4}`"},", $keyNum, $slotKeyNum, $funcName, $argumentValue, $code)



end loop all files



$endHandlers = "],"




Get-Content $methodsFileName | Out-File -FilePath $outputFileName -Append
$commaSpace | Out-File -FilePath $outputFileName -Append

Get-Content $eventsFileName | Out-File -FilePath $outputFileName -Append
"}" | Out-File -FilePath $outputFileName -Append

Get-Content $outputFileName | Set-Clipboard