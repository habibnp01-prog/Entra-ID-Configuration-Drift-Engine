function ConvertFrom-DriftRawResource {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$RawResources = @(),
        [Parameter(Mandatory)] [string]$ResourceType,
        [string]$IdProperty = "Id",
        [string]$NameProperty = "DisplayName"
    )

    $RawResources = @($RawResources)
    $out = @()

    foreach ($r in $RawResources) {
        if ($null -eq $r) { continue }

        $idProp   = $r.PSObject.Properties | Where-Object { $_.Name -eq $IdProperty }   | Select-Object -First 1
        $nameProp = $r.PSObject.Properties | Where-Object { $_.Name -eq $NameProperty } | Select-Object -First 1

        $id = if ($idProp) { $idProp.Value } else { $null }
        $name = if ($nameProp) { $nameProp.Value } else { $null }

        $properties = [ordered]@{}
        foreach ($prop in ($r.PSObject.Properties | Sort-Object Name)) {
            if ($prop.Name -in @("Id","id","DisplayName","displayName","AdditionalProperties","@odata.context","@odata.type")) { continue }
            if ($prop.Name -in @("CreatedDateTime","createdDateTime","ModifiedDateTime","modifiedDateTime","DeletedDateTime","deletedDateTime")) { continue }
            $properties[$prop.Name] = $prop.Value
        }

        $out += [PSCustomObject]@{
            ResourceType = $ResourceType
            ResourceId   = $id
            DisplayName  = $name
            Properties   = [PSCustomObject]$properties
        }
    }

    return ,$out
}
