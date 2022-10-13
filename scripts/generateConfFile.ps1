$slots = "{`"slots`":{`"0`":{`"name`":`"core`",`"type`":{`"events`":[],`"methods`":[]}},`"1`":{`"name`":`"atmofueltank_1`",`"type`":{`"events`":[],`"methods`":[]}},`"2`":{`"name`":`"screenMain`",`"type`":{`"events`":[],`"methods`":[]}},`"3`":{`"name`":`"screenTelemetry`",`"type`":{`"events`":[],`"methods`":[]}},`"4`":{`"name`":`"slot5`",`"type`":{`"events`":[],`"methods`":[]}},`"5`":{`"name`":`"slot6`",`"type`":{`"events`":[],`"methods`":[]}},`"6`":{`"name`":`"slot7`",`"type`":{`"events`":[],`"methods`":[]}},`"7`":{`"name`":`"slot8`",`"type`":{`"events`":[],`"methods`":[]}},`"8`":{`"name`":`"slot9`",`"type`":{`"events`":[],`"methods`":[]}},`"9`":{`"name`":`"slot10`",`"type`":{`"events`":[],`"methods`":[]}},`"-1`":{`"name`":`"unit`",`"type`":{`"events`":[],`"methods`":[]}},`"-3`":{`"name`":`"player`",`"type`":{`"events`":[],`"methods`":[]}},`"-2`":{`"name`":`"construct`",`"type`":{`"events`":[],`"methods`":[]}},`"-4`":{`"name`":`"system`",`"type`":{`"events`":[],`"methods`":[]}},`"-5`":{`"name`":`"library`",`"type`":{`"events`":[],`"methods`":[]}}}"
$outputFileName = "Elevator.conf.json"

enum SlotKeyNum
{
    library = -5
    system = -4
    construct = -2
    player = -3
    unit = -1
    core = 0
}

$sourceDirectory = Get-Location
$sourceDirectory = $sourceDirectory.t + (Get-ChildItem -Path $sourceDirectory) -like "src"
$fullFileNames = (Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).FullName 
$directories = ((Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).Directory).BaseName
$files = (Get-ChildItem -Path $sourceDirectory -Recurse -Include *.lua).BaseName
$regexBetweenParens = [regex]"([^()]+)"
$regexBetweenNestedParens = [regex]"\((?>\((?<c>)|[^()]+|\)(?<-c>))*(?(c)(?!))\)"

$output = $slots + ",`"handlers`":["

for($i = 0; $i -lt $directories.Count; $i++)
{
    $keyNum = $i
    $slotKeyNum = [int][SlotKeyNum]::($directories[$i])
    $funcName = $files[$i]
    if([regex]::Matches($funcName, $regexBetweenParens).Count -ge 2)
    {
        $funcName = $funcName -join "(tag)" #Game replaces custom tags with the word tag
        $argumentValue = ("{`"value`": `"" + [regex]::Matches($funcName, $regexBetweenParens)[1] + """}")
    }   
    else {
        $argumentValue = ""
    }

    #remove comments from code section
    $code = ""
    foreach($line in [System.IO.File]::ReadLines($fullFileNames[$i]))
    {
        if($line.Contains("--"))
        {
            $line = $line.Split("--")
            $code = $code + $line[0]
        }
        else {
            $code = $code + $line + "\n"
        }
    }

    if($i -eq $directories.Count -1)
    {
        $rowString = ("{`"code`":`"$code`",`"filter`":{`"args`":[$argumentValue],`"signature`":`"$funcName`",`"slotKey`":`"$slotKeyNum`"},`"key`":`"$keyNum`"}")
    }
    else {
        $rowString = ("{`"code`":`"$code`",`"filter`":{`"args`":[$argumentValue],`"signature`":`"$funcName`",`"slotKey`":`"$slotKeyNum`"},`"key`":`"$keyNum`"}, ")
    }
    
    $output = $output + $rowString
}

$output = $output + "], `"methods`": [], `"events`": []}"

#Removing all white space
#$fileContents = [string]::join("",($fileContents.Split("`n")))
#$fileContents = $fileContents -replace '\s+', '' 

#Pattern matching to esacpe all strings that are part of a parameter
$quotesBetweenNestedParens = [regex]::Matches($output, $regexBetweenNestedParens)
$escapedQuotesBetweenNestedParens = [regex]::Matches($output, $regexBetweenNestedParens) -replace ("`"","\`"")

for($i = 0; $i -lt $quotesBetweenNestedParens.Count; $i++)
{
    #only do large string replace when there was actually a change
    if($escapedQuotesBetweenNestedParens[$i].Contains("`"")) 
    {
        $output = $output.Replace($quotesBetweenNestedParens[$i], $escapedQuotesBetweenNestedParens[$i])
    }
}

$output = $output.Replace("`t","    ")
#$output = $output.Replace("\`"\n\`"","\n")
$output | Out-File -FilePath $outputFileName -Force
$output | Set-Clipboard