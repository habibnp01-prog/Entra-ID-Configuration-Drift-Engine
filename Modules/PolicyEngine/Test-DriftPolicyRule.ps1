function Test-DriftPolicyRule {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] $Policy,
        [Parameter(Mandatory)] $Resource
    )

    $result = Get-DriftDotPath -Object $Resource.Properties -Path $Policy.property

    $passes = $false
    $reason = ""

    switch ($Policy.rule) {
        "MustExist" {
            $passes = $result.Exists
            $reason = if ($passes) { "Property exists." } else { "Property does not exist." }
        }
        "Required" {
            $passes = $result.Exists -and ($null -ne $result.Value) -and ("$($result.Value)" -ne "")
            $reason = if ($passes) { "Property present and non-empty." } else { "Property missing or empty." }
        }
        "MustBe" {
            $passes = $result.Exists -and ("$($result.Value)" -eq "$($Policy.value)")
            $reason = if ($passes) { "Value matches expected." } else { "Value does not match expected." }
        }
        "MustNotBe" {
            $passes = -not $result.Exists -or ("$($result.Value)" -ne "$($Policy.value)")
            $reason = if ($passes) { "Value is not the prohibited value." } else { "Value matches prohibited value." }
        }
        "MustBeOneOf" {
            $allowed = @($Policy.value)
            $passes = $result.Exists -and ("$($result.Value)" -in $allowed)
            $reason = if ($passes) { "Value is in allowed set." } else { "Value is not in allowed set." }
        }
        "MustNotBeOneOf" {
            $prohibited = @($Policy.value)
            $passes = -not $result.Exists -or ("$($result.Value)" -notin $prohibited)
            $reason = if ($passes) { "Value is not in prohibited set." } else { "Value is in prohibited set." }
        }
        default {
            $passes = $false
            $reason = ("Unknown rule: {0}" -f $Policy.rule)
        }
    }

    [PSCustomObject]@{
        PolicyId     = $Policy.id
        Passes       = $passes
        Property     = $Policy.property
        ExpectedValue = $Policy.value
        ObservedValue = $result.Value
        PropertyExists = $result.Exists
        Reason       = $reason
    }
}
