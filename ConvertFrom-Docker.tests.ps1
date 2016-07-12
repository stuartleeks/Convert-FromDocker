$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".tests.", ".")
$global:poshhumpSkipTabCompletionInstall = $true

function ConvertTo-Hashtable($value){
    $value.PSObject.Properties | foreach `
        -begin   { $hash = @{} } `
        -process { $hash[$_.Name]=$_.Value } `
        -end     { $hash }
}

Describe "No input rows" {
	It "returns no results" {
        $testInput = @(
            "CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES"
            )        
		$result = @($testInput | &"$here\$sut")
		$result.Length | Should Be 0
	}
}
Describe "Single input row" {
	It "returns single result" {
        $testInput = @(
            "CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES",
            "IdOne               theImage            theCommand          foo                 Running             12345               Bob,Alice"
            )        
		$result = @($testInput | &"$here\$sut")
		$result.Length | Should Be 1    
	}
	It "returns single result with correct property names" {
        $testInput = @(
            "CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES",
            "IdOne               theImage            theCommand          foo                 Running             12345               Bob,Alice"
            )        
		$result = @($testInput | &"$here\$sut")
		$propertyNames = $result[0].PSObject.Properties | Select -ExpandProperty Name | Sort    

        ,$propertyNames | Should MatchArrayUnOrdered @('ContainerId', 'Image', 'Command', 'Created', 'Status', 'Ports', 'Names')
	}
	It "returns single result with correct property values" {
        $testInput = @(
            "CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES",
            "IdOne               theImage            theCommand          foo                 Running             12345               Bob,Alice"
            )        
		$result = @($testInput | &"$here\$sut")

        $expected = @{
            "ContainerId"="IdOne"
            "Image"="theImage"
            "Command"="theCommand"
            "Created"="foo"
            "Status"="Running"
            "Ports"="12345"
            "Names"="Bob,Alice"
        }
        $resultHash = ConvertTo-Hashtable $result[0]
		$resultHash | Should MatchHashtable $expected    
	}
}
Describe "Multiple input rows" {
    It "returns the correct data"{
        $testInput = @(
            "PROPERTY A        SECOND",
            "123               abc",
            "456               asd",
            "789               qwe"
            )        
		$result = @($testInput | &"$here\$sut")

        $expected = @(
            @{
                "PropertyA" = "123"
                "Second" = "abc"
            },
            @{
                "PropertyA" = "456"
                "Second" = "asd"
            },
            @{
                "PropertyA" = "789"
                "Second" = "qwe"
            }
        ) 
		$result.Length | Should Be $expected.Count

        for ($i = 0; $i -lt $result.Count; $i++) {
            ConvertTo-Hashtable $result[$i] | Should MatchHashtable $expected[$i]    
        }
    }
}