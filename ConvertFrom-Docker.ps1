
<#PSScriptInfo

.VERSION 0.0.2

.GUID c62ee4be-fc92-4ef8-aa20-af179105702a

.AUTHOR Stuart Leeks

.COMPANYNAME 

.COPYRIGHT 

.TAGS docker

.LICENSEURI https://github.com/stuartleeks/ConvertFrom-Docker/blob/master/LICENSE.md

.PROJECTURI https://github.com/stuartleeks/ConvertFrom-Docker

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 Script to parse docker output into PowerShell objects 

#> 

Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    $input 
)


function local:PascalName($name){
    $parts = $name.Split(" ")
    for($i = 0 ; $i -lt $parts.Length ; $i++){
        $parts[$i] = [char]::ToUpper($parts[$i][0]) + $parts[$i].SubString(1).ToLower();
    }
    $parts -join ""
}
function local:GetHeaderBreak($headerRow, $startPoint=0){
    $i = $startPoint
    while( $i + 1  -lt $headerRow.Length)
    {
        if ($headerRow[$i] -eq ' ' -and $headerRow[$i+1] -eq ' '){
            return $i
            break
        }
        $i += 1
    }
    return -1
}
function local:GetHeaderNonBreak($headerRow, $startPoint=0){
    $i = $startPoint
    while( $i + 1  -lt $headerRow.Length)
    {
        if ($headerRow[$i] -ne ' '){
            return $i
            break
        }
        $i += 1
    }
    return -1
}
function local:GetColumnInfo($headerRow){
    $lastIndex = 0
    $i = 0
    while ($i -lt $headerRow.Length){
        $i = GetHeaderBreak $headerRow $lastIndex
        if ($i -lt 0){
            $name = $headerRow.Substring($lastIndex)
            New-Object PSObject -Property @{ HeaderName = $name; Name = PascalName $name; Start=$lastIndex; End=-1}
            break
        } else {
            $name = $headerRow.Substring($lastIndex, $i-$lastIndex)
            $temp = $lastIndex
            $lastIndex = GetHeaderNonBreak $headerRow $i
            New-Object PSObject -Property @{ HeaderName = $name; Name = PascalName $name; Start=$temp; End=$lastIndex}
       }
    }
}
function local:ParseRow($row, $columnInfo) {
    $values = @{}
    $columnInfo | ForEach-Object {
        if ($_.End -lt 0) {
            $len = $row.Length - $_.Start
        } else {
            $len = $_.End - $_.Start
        }
        $values[$_.Name] = $row.SubString($_.Start, $len).Trim()
    }
    New-Object PSObject -Property $values
}
function local:ConvertFrom-Docker(){
    begin{
        $positions = $null;
    }
    process {
        if($positions -eq $null) {
            # header row => determine column positions
            $positions  = GetColumnInfo -headerRow $_  #-propertyNames $propertyNames
        } else {
            # data row => output!
            ParseRow -row $_ -columnInfo $positions
        }
    }
    end {
    }
}
# e.g. :
# docker --tls ps -a --no-trunc | ConvertFrom-Docker | ft

$input | ConvertFrom-Docker