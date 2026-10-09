function ConvertTo-DriftNormalizedResource {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)] $Resource,
        [Parameter(Mandatory)] [string]$ResourceType
    )

    process {
        $id = if ($Resource.Id) { $Resource.Id } elseif ($Resource.id) { $Resource.id } else { $null }
        $name = if ($Resource.DisplayName) { $Resource.DisplayName } elseif ($Resource.displayName) { $Resource.displayName } else { $null }

        $properties = [ordered]@{}
        foreach ($prop in ($Resource.PSObject.Properties | Sort-Object Name)) {
            if ($prop.Name -in @("Id","id","DisplayName","displayName","AdditionalProperties","@odata.context","@odata.type")) { continue }
            if ($prop.Name -in @("CreatedDateTime","createdDateTime","ModifiedDateTime","modifiedDateTime")) { continue }
            $properties[$prop.Name] = $prop.Value
        }

        [PSCustomObject]@{
            ResourceType = $ResourceType
            ResourceId   = $id
            DisplayName  = $name
            Properties   = [PSCustomObject]$properties
        }
    }
}
