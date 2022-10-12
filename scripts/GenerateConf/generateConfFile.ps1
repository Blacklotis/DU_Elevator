$slotsFileName = "scripts\GenerateConf\confSlots.txt"
$eventsFileName = "scripts\GenerateConf\confEvents.txt"
$methodsFileName = "scripts\GenerateConf\confMethods.txt"
$outputFileName = "Elevator.conf.json"
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
$sourceDirectory = $sourceDirectory.t + (Get-ChildItem -Path $sourceDirectory) -like "src"
$fullFileNames = (Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).FullName 
$directories = ((Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).Directory).BaseName
$files = (Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).BaseName
$regexBetweenParens = [regex]"([^()]+)"
$regexBetweenNestedParens = [regex]"\((?>\((?<c>)|[^()]+|\)(?<-c>))*(?(c)(?!))\)"

for($i = 0; $i -lt $directories.Count; $i++)
{
    $keyNum = $i
    $slotKeyNum = [int][SlotKeyNum]::($directories[$i])
    $funcName = $files[$i]
    if([regex]::Matches($funcName, $regexBetweenParens).Count -ge 2)
    {
        $funcName = $funcName -join "(tag)" #Game replaces custom tags witht he word tag
        $argumentValue = "{`"value`": `"" + [regex]::Matches($funcName, $regexBetweenParens)[1] + """}" 
    }   
    else {
        $argumentValue = ""
    }
    $code = [System.IO.File]::ReadAllText($fullFileNames[$i])
    $rowString = "{`"code`":`"$code`",`"filter`":{`"args`":[$argumentValue],`"signature`":`"$funcName`",`"slotKey`":`"$slotKeyNum`"},`"key`":`"$keyNum`"}"
    
    $rowString | Out-File -FilePath $outputFileName -Append
}

$endHandlers = "],"
$endHandlers | Out-File -FilePath $outputFileName -Append

Get-Content $methodsFileName | Out-File -FilePath $outputFileName -Append
$commaSpace | Out-File -FilePath $outputFileName -Append

Get-Content $eventsFileName | Out-File -FilePath $outputFileName -Append
"}" | Out-File -FilePath $outputFileName -Append

#Removing all white space
$fileContents = Get-Content $outputFileName 
$fileContents = [string]::join("",($fileContents.Split("`n")))
$fileContents = $fileContents -replace '\s+', '' 

#Pattern matching to esacpe all strings that are part of a parameter
$quotesBetweenNestedParens = [regex]::Matches($fileContents, $regexBetweenNestedParens)
$escapedQuotesBetweenNestedParens = [regex]::Matches($fileContents, $regexBetweenNestedParens) -replace ("`"","\`"")

for($i = 0; $i -lt $quotesBetweenNestedParens.Count; $i++)
{
    #only do large string replace when there was actually a change
    if($escapedQuotesBetweenNestedParens[$i].Contains("`"")) 
    {
        $fileContents = $fileContents.Replace($quotesBetweenNestedParens[$i], $escapedQuotesBetweenNestedParens[$i])
    }
}

$fileContents | Out-File -FilePath $outputFileName -Force
$fileContents | Set-Clipboard