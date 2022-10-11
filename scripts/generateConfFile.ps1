$slotsFileName = "scripts\resources\confSlots.txt"
$eventsFileName = "scripts\resources\confEvents.txt"
$methodsFileName = "scripts\resources\confMethods.txt"
$outputFileName = "Elevator.conf"
$commaSpace = ", "

enum SlotKeyNum
{
    library = -5
    system = -4
    construct = -2
    player = -3
    unit = -1
    core = 0
}

Get-Content $slotsFileName | Out-File -FilePath $outputFileName
$commaSpace | Out-File -FilePath $outputFileName -Append

$startHandlers = "`"handlers`":["
$startHandlers | Out-File -FilePath $outputFileName -Append

$sourceDirectory = Get-Location
$fullFileNames = (Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).FullName
$directories = ((Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).Directory).BaseName
$files = (Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).BaseName
$regex = [regex]"([^()]+)"

for($i = 0; $i -lt $directories.Count; $i++)
{
    $keyNum = $i
    $slotKeyNum = [int][SlotKeyNum]::($directories[$i])
    $funcName = $files[$i]
    if([regex]::Matches($funcName, $regex).Count -ge 2)
    {
        $funcName = $funcName -join "(tag)"
        $argumentValue = "{`"value`": `"" + [regex]::Matches($funcName, $regex)[1] + """}" 
    }   
    else {
        $argumentValue = ""
    }
    $code = [System.IO.File]::ReadAllText($fullFileNames[$i])
    #first try: $rowString = "{`"key`": `"{$keyNum}`", `"filter`": {`"slotKey`": `"{$slotKeyNum}`", `"signature`": `"{$funcName}`", `"args`": [{$argumentValue}]}, `"code`": `"{$code}`"},"
    #example from game: {"code":"","filter":{"args":[{"value":"strafeleft"}],"signature":"onActionStop(strafeleft)","slotKey":"-4"},"key":"19"}
    $rowString = "{`"code`":`"$code`",`"filter`":{`"args`":[$argumentValue],`"signature`":`"$funcName`",`"slotKey`":`"$slotKeyNum`"},`"key`":`"$keyNum`"}"
    
    $rowString | Out-File -FilePath $outputFileName -Append
}

#{"code":"","filter":{"args":[{"value":"brake"}],"signature":"onActionLoop(brake)","slotKey":"-4"},"key":"34"}


$endHandlers = "],"
$endHandlers | Out-File -FilePath $outputFileName -Append

Get-Content $methodsFileName | Out-File -FilePath $outputFileName -Append
$commaSpace | Out-File -FilePath $outputFileName -Append

Get-Content $eventsFileName | Out-File -FilePath $outputFileName -Append
"}" | Out-File -FilePath $outputFileName -Append

$fileContents = Get-Content $outputFileName 
$fileContents = [string]::join("",($fileContents.Split("`n")))
$fileContents = $fileContents -replace '\s+', '' 

$fileContents | Set-Clipboard