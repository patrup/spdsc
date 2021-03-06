function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $AllowUserFormBrowserEnabling,

        [Parameter()]
        [System.Boolean]
        $AllowUserFormBrowserRendering,

        [Parameter()]
        [System.UInt32]
        $MaxDataConnectionTimeout,

        [Parameter()]
        [System.UInt32]
        $DefaultDataConnectionTimeout,

        [Parameter()]
        [System.UInt32]
        $MaxDataConnectionResponseSize,

        [Parameter()]
        [System.Boolean]
        $RequireSslForDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowEmbeddedSqlForDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowUdcAuthenticationForDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowUserFormCrossDomainDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowEventPropagation,

        [Parameter()]
        [System.UInt16]
        $MaxPostbacksPerSession,

        [Parameter()]
        [System.UInt16]
        $MaxUserActionsPerPostback,

        [Parameter()]
        [System.UInt16]
        $ActiveSessionsTimeout,

        [Parameter()]
        [System.UInt16]
        $MaxSizeOfUserFormState
    )

    Write-Verbose -Message "Getting InfoPath Forms Service Configuration"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $config = Get-SPInfoPathFormsService
        $nullReturn = @{
            IsSingleInstance                         = "Yes"
            AllowUserFormBrowserEnabling             = $params.AllowUserFormBrowserEnabling
            AllowUserFormBrowserRendering            = $params.AllowUserFormBrowserRendering
            MaxDataConnectionTimeout                 = $params.MaxDataConnectionTimeout
            DefaultDataConnectionTimeout             = $params.DefaultDataConnectionTimeout
            MaxDataConnectionResponseSize            = $params.MaxDataConnectionResponseSize
            RequireSslForDataConnections             = $params.RequireSslForDataConnections
            AllowEmbeddedSqlForDataConnections       = $params.AllowEmbeddedSqlForDataConnections
            AllowUdcAuthenticationForDataConnections = $params.AllowUdcAuthenticationForDataConnections
            AllowUserFormCrossDomainDataConnections  = $params.AllowUserFormCrossDomainDataConnections
            AllowEventPropagation                    = $params.AllowEventPropagation
            MaxPostbacksPerSession                   = $params.MaxPostbacksPerSession
            MaxUserActionsPerPostback                = $params.MaxUserActionsPerPostback
            ActiveSessionsTimeout                    = $params.ActiveSessionsTimeout
            MaxSizeOfUserFormState                   = ($params.MaxSizeOfUserFormState / 1024)
            Ensure                                   = "Absent"
        }
        if ($null -eq $config)
        {
            return $nullReturn
        }

        return @{
            IsSingleInstance                         = "Yes"
            AllowUserFormBrowserEnabling             = $config.AllowUserFormBrowserEnabling
            AllowUserFormBrowserRendering            = $config.AllowUserFormBrowserRendering
            MaxDataConnectionTimeout                 = $config.MaxDataConnectionTimeout
            DefaultDataConnectionTimeout             = $config.DefaultDataConnectionTimeout
            MaxDataConnectionResponseSize            = $config.MaxDataConnectionResponseSize
            RequireSslForDataConnections             = $config.RequireSslForDataConnections
            AllowEmbeddedSqlForDataConnections       = $config.AllowEmbeddedSqlForDataConnections
            AllowUdcAuthenticationForDataConnections = $config.AllowUdcAuthenticationForDataConnections
            AllowUserFormCrossDomainDataConnections  = $config.AllowUserFormCrossDomainDataConnections
            AllowEventPropagation                    = $config.AllowEventPropagation
            MaxPostbacksPerSession                   = $config.MaxPostbacksPerSession
            MaxUserActionsPerPostback                = $config.MaxUserActionsPerPostback
            ActiveSessionsTimeout                    = $config.ActiveSessionsTimeout
            MaxSizeOfUserFormState                   = ($config.MaxSizeOfUserFormState / 1024)
            Ensure                                   = "Present"
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $AllowUserFormBrowserEnabling,

        [Parameter()]
        [System.Boolean]
        $AllowUserFormBrowserRendering,

        [Parameter()]
        [System.UInt32]
        $MaxDataConnectionTimeout,

        [Parameter()]
        [System.UInt32]
        $DefaultDataConnectionTimeout,

        [Parameter()]
        [System.UInt32]
        $MaxDataConnectionResponseSize,

        [Parameter()]
        [System.Boolean]
        $RequireSslForDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowEmbeddedSqlForDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowUdcAuthenticationForDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowUserFormCrossDomainDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowEventPropagation,

        [Parameter()]
        [System.UInt16]
        $MaxPostbacksPerSession,

        [Parameter()]
        [System.UInt16]
        $MaxUserActionsPerPostback,

        [Parameter()]
        [System.UInt16]
        $ActiveSessionsTimeout,

        [Parameter()]
        [System.UInt16]
        $MaxSizeOfUserFormState
    )

    Write-Verbose -Message "Setting InfoPath Forms Service Configuration"

    if ($Ensure -eq "Absent")
    {
        $message = ("This resource cannot undo InfoPath Forms Service Configuration changes. " + `
                "Please set Ensure to Present or omit the resource")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $config = Get-SPInfoPathFormsService

        if ($params.ContainsKey("AllowUserFormBrowserEnabling"))
        {
            $config.AllowUserFormBrowserEnabling = $params.AllowUserFormBrowserEnabling
        }

        if ($params.ContainsKey("AllowUserFormBrowserRendering"))
        {
            $config.AllowUserFormBrowserRendering = $params.AllowUserFormBrowserRendering
        }

        if ($params.ContainsKey("MaxDataConnectionTimeout"))
        {
            $config.MaxDataConnectionTimeout = $params.MaxDataConnectionTimeout
        }

        if ($params.ContainsKey("DefaultDataConnectionTimeout"))
        {
            $config.DefaultDataConnectionTimeout = $params.DefaultDataConnectionTimeout
        }

        if ($params.ContainsKey("MaxDataConnectionResponseSize"))
        {
            $config.MaxDataConnectionResponseSize = $params.MaxDataConnectionResponseSize
        }

        if ($params.ContainsKey("RequireSslForDataConnections"))
        {
            $config.RequireSslForDataConnections = $params.RequireSslForDataConnections
        }

        if ($params.ContainsKey("AllowEmbeddedSqlForDataConnections"))
        {
            $config.AllowEmbeddedSqlForDataConnections = $params.AllowEmbeddedSqlForDataConnections
        }

        if ($params.ContainsKey("AllowUdcAuthenticationForDataConnections"))
        {
            $config.AllowUdcAuthenticationForDataConnections = $params.AllowUdcAuthenticationForDataConnections
        }

        if ($params.ContainsKey("AllowUserFormCrossDomainDataConnections"))
        {
            $config.AllowUserFormCrossDomainDataConnections = $params.AllowUserFormCrossDomainDataConnections
        }

        if ($params.ContainsKey("AllowEventPropagation"))
        {
            $config.AllowEventPropagation = $params.AllowEventPropagation
        }

        if ($params.ContainsKey("MaxPostbacksPerSession"))
        {
            $config.MaxPostbacksPerSession = $params.MaxPostbacksPerSession
        }

        if ($params.ContainsKey("MaxUserActionsPerPostback"))
        {
            $config.MaxUserActionsPerPostback = $params.MaxUserActionsPerPostback
        }

        if ($params.ContainsKey("ActiveSessionsTimeout"))
        {
            $config.ActiveSessionsTimeout = $params.ActiveSessionsTimeout
        }

        if ($params.ContainsKey("MaxSizeOfUserFormState"))
        {
            $config.MaxSizeOfUserFormState = ($params.MaxSizeOfUserFormState * 1024)
        }

        $config.Update()
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $AllowUserFormBrowserEnabling,

        [Parameter()]
        [System.Boolean]
        $AllowUserFormBrowserRendering,

        [Parameter()]
        [System.UInt32]
        $MaxDataConnectionTimeout,

        [Parameter()]
        [System.UInt32]
        $DefaultDataConnectionTimeout,

        [Parameter()]
        [System.UInt32]
        $MaxDataConnectionResponseSize,

        [Parameter()]
        [System.Boolean]
        $RequireSslForDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowEmbeddedSqlForDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowUdcAuthenticationForDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowUserFormCrossDomainDataConnections,

        [Parameter()]
        [System.Boolean]
        $AllowEventPropagation,

        [Parameter()]
        [System.UInt16]
        $MaxPostbacksPerSession,

        [Parameter()]
        [System.UInt16]
        $MaxUserActionsPerPostback,

        [Parameter()]
        [System.UInt16]
        $ActiveSessionsTimeout,

        [Parameter()]
        [System.UInt16]
        $MaxSizeOfUserFormState
    )

    Write-Verbose -Message "Testing the InfoPath Form Services Configuration"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure",
        "AllowUserFormBrowserEnabling",
        "AllowUserFormBrowserRendering",
        "MaxDataConnectionTimeout",
        "DefaultDataConnectionTimeout",
        "MaxDataConnectionResponseSize",
        "RequireSslForDataConnections",
        "AllowEmbeddedSqlForDataConnections",
        "AllowUdcAuthenticationForDataConnections",
        "AllowUserFormCrossDomainDataConnections",
        "AllowEventPropagation",
        "MaxPostbacksPerSession",
        "MaxUserActionsPerPostback",
        "ActiveSessionsTimeout",
        "MaxSizeOfUserFormState")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
