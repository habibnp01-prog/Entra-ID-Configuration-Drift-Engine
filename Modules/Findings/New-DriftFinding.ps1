function New-DriftFinding {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$FindingId,
        [Parameter(Mandatory)] [string]$Category,
        [Parameter(Mandatory)] [string]$Severity,
        [Parameter(Mandatory)] [string]$ResourceType,
        [Parameter(Mandatory)] [string]$ResourceId,
        [string]$ResourceName,
        [string]$ChangedProperty,
        $ExpectedValue,
        $ObservedValue,
        [string]$BusinessImpact,
        [string]$Recommendation,
        [string]$BaselineVersion,
        [string]$Confidence = "High"
    )

    [PSCustomObject]@{
        FindingId        = $FindingId
        Category         = $Category
        Severity         = $Severity
        ResourceType     = $ResourceType
        ResourceId       = $ResourceId
        ResourceName     = $ResourceName
        ChangedProperty  = $ChangedProperty
        ExpectedValue    = $ExpectedValue
        ObservedValue    = $ObservedValue
        DetectedAtUtc    = (Get-Date).ToUniversalTime().ToString("o")
        Evidence         = [PSCustomObject]@{
            BaselineVersion = $BaselineVersion
            Source          = "Comparison"
        }
        BusinessImpact   = $BusinessImpact
        Recommendation   = $Recommendation
        BaselineVersion  = $BaselineVersion
        Confidence       = $Confidence
    }
}
