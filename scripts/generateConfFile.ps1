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
$sourceDirectory = Get-Location + "/src"
$fullFileNames = (Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).FullName
$directories = ((Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).Directory).BaseName
$files = (Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).Name
$regex = [regex]"([^()]+)"

for($i = 0; $i -le $directories.Count; $i++)
{
    $keyNum = $i
    $slotKeyNum = [int][SlotKeyNum]::$folder
    $funcName = $files[$i]
    if([regex]::Matches($funcName, $regex).Count -gt 2)
    {
        $argumentValue = "{`"" + [regex]::Matches($funcName, $regex)[0] + "`": `"" + [regex]::Matches($funcName, $regex)[1] + """}" 
    }   
    else {
        $argumentValue = ""
    }
    $code = [System.IO.File]::ReadAllText($fullFileNames[$i])
    $rowString = "{`"key`": `"{$keyNum}`", `"filter`": {`"slotKey`": `"{$slotKeyNum}`", `"signature`": `"{$funcName}`", `"args`": [{$argumentValue}]}, `"code`": `"{$code}`"},"
}

$endHandlers = "],"

Get-Content $methodsFileName | Out-File -FilePath $outputFileName -Append
$commaSpace | Out-File -FilePath $outputFileName -Append

Get-Content $eventsFileName | Out-File -FilePath $outputFileName -Append
"}" | Out-File -FilePath $outputFileName -Append

Get-Content $outputFileName | Set-Clipboard