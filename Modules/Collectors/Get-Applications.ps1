function Get-DriftApplications {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if (-not (Test-DriftGraphConnection)) {
        throw "Not connected to Microsoft Graph. Call Connect-DriftGraph first."
    }

    Write-DriftLog -Message "Fetching applications..." -Level Info -Component "Collect"

    $apps = Get-MgApplication -All -Property "Id,AppId,DisplayName,SignInAudience,PublisherDomain,CreatedDateTime,RequiredResourceAccess,PasswordCredentials,KeyCredentials,PublicClient" -ErrorAction Stop
    $apps = @($apps)

    Write-DriftLog -Message ("Retrieved {0} applications." -f $apps.Count) -Level Success -Component "Collect"
    return ,$apps
}
