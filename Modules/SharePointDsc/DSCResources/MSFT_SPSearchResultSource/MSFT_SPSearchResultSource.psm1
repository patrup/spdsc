function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
<<<<<<< HEAD
        [ValidateSet("SSA",
                     "SPSite",
                     "SPWeb")]
        [System.String]
        $ScopeName,

        [Parameter(Mandatory = $true)]
=======
>>>>>>> upstream/dev
        [System.String]
        $SearchServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Exchange Search Provider",
                     "Local People Provider",
                     "Local SharePoint Provider",
                     "OpenSearch Provider",
                     "Remote People Provider",
                     "Remote SharePoint Provider")]
        [System.String]
        $ProviderType,

        [Parameter()]
        [System.String]
<<<<<<< HEAD
        $ScopeUrl,

        [Parameter()]
        [System.String]
        $ConnectionUrl,

        [Parameter()]
=======
        $ConnectionUrl,

        [Parameter()]
        [System.String]
        $ScopeUrl,

        [Parameter()]
>>>>>>> upstream/dev
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting search result source '$Name'"
    if($ScopeName -ne "SSA" -and "" -eq $ScopeUrl)
    {
        throw "When specifying a ScopeName of type $($ScopeName) you also need to provide" + `
        " a ScopeUrl value."
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        [void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search")

        $nullReturn = @{
            Name = $params.Name
            ScopeName = $params.ScopeName
            SearchServiceAppName = $params.SearchServiceAppName
            Query = $null
            ProviderType = $null
            ConnectionUrl = $null
            ScopeUrl = $null
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        }
        $serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.SearchServiceAppName

        $fedManager = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($serviceApp)
        $searchOwner = $null
        if ("ssa" -eq $params.ScopeName.ToLower())
        {
            $searchOwner = Get-SPEnterpriseSearchOwner -Level SSA
        }
        else
        {
            $searchOwner = Get-SPEnterpriseSearchOwner -Level $params.ScopeName -SPWeb $params.ScopeUrl
        }

<<<<<<< HEAD
        $filter = New-Object Microsoft.Office.Server.Search.Administration.SearchObjectFilter($searchOwner)
        $filter.IncludeHigherLevel = $true

        $source = $fedManager.ListSources($filter,$true) | Where-Object -FilterScript {
            $_.Name -eq $params.Name
=======
        $adminNamespace = "Microsoft.Office.Server.Search.Administration"
        $queryNamespace = "Microsoft.Office.Server.Search.Administration.Query"
        $objectLevel = [Microsoft.Office.Server.Search.Administration.SearchObjectLevel]

        $fedManager = $null
        if ($null -eq $params.ScopeUrl)
        {
            $fedManager = New-Object -TypeName "$queryNamespace.FederationManager" `
                                    -ArgumentList $serviceApp
            $searchOwner = New-Object -TypeName "$adminNamespace.SearchObjectOwner" `
                                    -ArgumentList @(
                                        $objectLevel::Ssa,
                                        $searchSite
                                    )

            $source = $fedManager.GetSourceByName($params.Name, $searchOwner)
        }
        else
        {
            $fedManager = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($serviceApp)
            $searchOwner = Get-SPEnterpriseSearchOwner -Level SPWeb -SPWeb $params.ScopeUrl
            $filter = New-Object Microsoft.Office.Server.Search.Administration.SearchObjectFilter($searchOwner)
            $filter.IncludeHigherLevel = $false
            $source = $fedManager.ListSources($filter,$true) | Where-Object -FilterScript {
                $_.Name -eq $params.Name
            }
>>>>>>> upstream/dev
        }

        if ($null -ne $source)
        {
            $providers = $fedManager.ListProviders()
            $provider = $providers.Values | Where-Object -FilterScript {
                $_.Id -eq $source.ProviderId
            }
            return @{
                Name = $params.Name
                ScopeName = $params.ScopeName
                SearchServiceAppName = $params.SearchServiceAppName
                Query = $source.QueryTransform.QueryTemplate
                ProviderType = $provider.DisplayName
                ConnectionUrl = $source.ConnectionUrlTemplate
                ScopeUrl = $params.ScopeUrl
                Ensure = "Present"
                InstallAccount = $params.InstallAccount
            }
        }
        else
        {
            return $nullReturn
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
<<<<<<< HEAD
        [ValidateSet("SSA",
                     "SPSite",
                     "SPWeb")]
        [System.String]
        $ScopeName,

        [Parameter(Mandatory = $true)]
=======
>>>>>>> upstream/dev
        [System.String]
        $SearchServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Exchange Search Provider",
                     "Local People Provider",
                     "Local SharePoint Provider",
                     "OpenSearch Provider",
                     "Remote People Provider",
                     "Remote SharePoint Provider")]
        [System.String]
        $ProviderType,

        [Parameter()]
        [System.String]
<<<<<<< HEAD
        $ScopeUrl,

        [Parameter()]
        [System.String]
        $ConnectionUrl,

        [Parameter()]
=======
        $ConnectionUrl,

        [Parameter()]
        [System.String]
        $ScopeUrl,

        [Parameter()]
>>>>>>> upstream/dev
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting search result source '$Name'"

    $CurrentValues = Get-TargetResource @PSBoundParameters
<<<<<<< HEAD
    if($ScopeName -ne "SSA" -and $null -eq $ScopeUrl)
    {
        throw "When specifying a ScopeName of type $($ScopeName) you also need to provide" + `
        " a ScopeUrl value."
    }
=======

>>>>>>> upstream/dev
    if ($CurrentValues.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating search result source $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]
            [void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search")

            $serviceApp = Get-SPEnterpriseSearchServiceApplication `
                            -Identity $params.SearchServiceAppName


            $fedManager =  New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($serviceApp)
            $searchOwner = $null
            if ("ssa" -eq $params.ScopeName.ToLower())
            {
                $searchOwner = Get-SPEnterpriseSearchOwner -Level SSA
            }
            else {
                $searchOwner = Get-SPEnterpriseSearchOwner -Level $params.ScopeName -SPWeb $params.ScopeUrl
            }

<<<<<<< HEAD
            $transformType = "Microsoft.Office.Server.Search.Query.Rules.QueryTransformProperties"
            $queryProperties = New-Object -TypeName $transformType
            $resultSource = $fedManager.CreateSource($searchOwner)

=======
            $fedManager = $null
            if ($null -eq $params.ScopeUrl)
            {
                $adminNamespace = "Microsoft.Office.Server.Search.Administration"
                $queryNamespace = "Microsoft.Office.Server.Search.Administration.Query"
                $objectLevel = [Microsoft.Office.Server.Search.Administration.SearchObjectLevel]
                $fedManager = New-Object -TypeName "$queryNamespace.FederationManager" `
                                        -ArgumentList $serviceApp
                $searchOwner = New-Object -TypeName "$adminNamespace.SearchObjectOwner" `
                                        -ArgumentList @(
                                            $objectLevel::Ssa,
                                            $searchSite
                                        )

                $transformType = "Microsoft.Office.Server.Search.Query.Rules.QueryTransformProperties"
                $queryProperties = New-Object -TypeName $transformType
                $resultSource = $fedManager.CreateSource($searchOwner)
            }
            else {
                $fedManager = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($serviceApp)
                $searchOwner = Get-SPEnterpriseSearchOwner -Level SPWeb -SPWeb $params.ScopeUrl
                $transformType = "Microsoft.Office.Server.Search.Query.Rules.QueryTransformProperties"
                $queryProperties = New-Object -TypeName $transformType
                $resultSource = $fedManager.CreateSource($searchOwner)
            }
>>>>>>> upstream/dev
            $resultSource.Name = $params.Name
            $providers = $fedManager.ListProviders()
            $provider = $providers.Values | Where-Object -FilterScript {
                $_.DisplayName -eq $params.ProviderType
            }
            $resultSource.ProviderId = $provider.Id
            $resultSource.CreateQueryTransform($queryProperties, $params.Query)
            if ($params.ContainsKey("ConnectionUrl") -eq $true)
            {
                $resultSource.ConnectionUrlTemplate = $params.ConnectionUrl
            }
            $resultSource.Commit()
        }
    }

    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing search result source $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            [void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search")

            $serviceApp = Get-SPEnterpriseSearchServiceApplication `
                            -Identity $params.SearchServiceAppName

<<<<<<< HEAD
            $fedManager = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($serviceApp)
            $searchOwner = $null
            if ("ssa" -eq $params.ScopeName.ToLower())
            {
                $searchOwner = Get-SPEnterpriseSearchOwner -Level SSA
            }
            else {
                $searchOwner = Get-SPEnterpriseSearchOwner -Level $params.ScopeName -SPWeb $params.ScopeUrl
            }
=======
            $searchSiteUrl = $serviceApp.SearchCenterUrl -replace "/pages"
            $searchSite = Get-SPWeb -Identity $searchSiteUrl

            $adminNamespace = "Microsoft.Office.Server.Search.Administration"
            $queryNamespace = "Microsoft.Office.Server.Search.Administration.Query"
            $objectLevel = [Microsoft.Office.Server.Search.Administration.SearchObjectLevel]
            $fedManager = New-Object -TypeName "$queryNamespace.FederationManager" `
                                     -ArgumentList $serviceApp
            $searchOwner = New-Object -TypeName "$adminNamespace.SearchObjectOwner" `
                                      -ArgumentList @(
                                          $objectLevel::Ssa,
                                          $searchSite
                                      )
>>>>>>> upstream/dev

            $source = $fedManager.GetSourceByName($params.Name, $searchOwner)
            if ($null -ne $source)
            {
                $fedManager.RemoveSource($source)
            }
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
<<<<<<< HEAD
        [ValidateSet("SSA",
                     "SPSite",
                     "SPWeb")]
        [System.String]
        $ScopeName,

        [Parameter(Mandatory = $true)]
=======
>>>>>>> upstream/dev
        [System.String]
        $SearchServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Exchange Search Provider",
                     "Local People Provider",
                     "Local SharePoint Provider",
                     "OpenSearch Provider",
                     "Remote People Provider",
                     "Remote SharePoint Provider")]
        [System.String]
        $ProviderType,

        [Parameter()]
        [System.String]
<<<<<<< HEAD
        $ScopeUrl,

        [Parameter()]
        [System.String]
        $ConnectionUrl,

        [Parameter()]
=======
        $ConnectionUrl,

        [Parameter()]
        [System.String]
        $ScopeUrl,

        [Parameter()]
>>>>>>> upstream/dev
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing search result source '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
