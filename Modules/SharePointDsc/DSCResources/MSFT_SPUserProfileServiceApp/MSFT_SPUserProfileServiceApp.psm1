function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [Parameter()]
        [System.String]
        $MySiteHostLocation,

        [Parameter()]
        [System.String]
        $ProfileDBName,

        [Parameter()]
        [System.String]
        $ProfileDBServer,

        [Parameter()]
        [System.String]
        $SocialDBName,

        [Parameter()]
        [System.String]
        $SocialDBServer,

        [Parameter()]
        [System.String]
        $SyncDBName,

        [Parameter()]
        [System.String]
        $SyncDBServer,

        [Parameter()]
        [System.Boolean]
        $EnableNetBIOS = $false,

        [Parameter()]
        [System.Boolean]
        $NoILMUsed = $false,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service application $Name"

    $farmAccountName = Invoke-SPDSCCommand -Credential $InstallAccount `
                                       -Arguments $PSBoundParameters `
                                       -ScriptBlock {
        return Get-SPDSCFarmAccountName
    }

    if ($null -ne $farmAccountName)
    {
        if ($PSBoundParameters.ContainsKey("InstallAccount") -eq $true)
        {
            # InstallAccount used
            if ($InstallAccount.UserName -eq $farmAccountName)
            {
                throw ("Specified InstallAccount ($($InstallAccount.UserName)) is the Farm " + `
                       "Account. Make sure the specified InstallAccount isn't the Farm Account " + `
                       "and try again")
            }
        }
        else
        {
            # PSDSCRunAsCredential or System
            if (-not $Env:USERNAME.Contains("$"))
            {
                # PSDSCRunAsCredential used
                $localaccount = "$($Env:USERDOMAIN)\$($Env:USERNAME)"
                if ($localaccount -eq $farmAccountName)
                {
                    throw ("Specified PSDSCRunAsCredential ($localaccount) is the Farm " + `
                           "Account. Make sure the specified PSDSCRunAsCredential isn't the " + `
                           "Farm Account and try again")
                }
            }
        }

        if ($FarmAccount.UserName -ne $farmAccountName)
        {
            throw ("Specified FarmAccount ($($FarmAccount.UserName)) isn't the Farm " + `
                    "Account. Make sure the specified FarmAccount is the actual Farm " + `
                    "Account and try again")
        }
    }
    else
    {
        throw ("Unable to retrieve the Farm Account. Check if the farm exists.")
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        $nullReturn = @{
            Name = $params.Name
            Ensure = "Absent"
            ApplicationPool = $params.ApplicationPool
        }
        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.Office.Server.Administration.UserProfileApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            $databases = @{}
            $propertyFlags = [System.Reflection.BindingFlags]::Instance `
                             -bor [System.Reflection.BindingFlags]::NonPublic

            $propData = $serviceApp.GetType().GetProperties($propertyFlags)

            $socialProp = $propData | Where-Object -FilterScript {
                $_.Name -eq "SocialDatabase"
            }
            $databases.Add("SocialDatabase", $socialProp.GetValue($serviceApp))

            $profileProp = $propData | Where-Object -FilterScript {
                $_.Name -eq "ProfileDatabase"
            }
            $databases.Add("ProfileDatabase", $profileProp.GetValue($serviceApp))

            $syncProp = $propData | Where-Object -FilterScript {
                $_.Name -eq "SynchronizationDatabase"
            }
            $databases.Add("SynchronizationDatabase", $syncProp.GetValue($serviceApp))

            $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue
            if ($null -ne $serviceAppProxies)
            {
                $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript {
                    $serviceApp.IsConnected($_)
                }
                if ($null -ne $serviceAppProxy)
                {
                    $proxyName = $serviceAppProxy.Name
                }
            }
            return @{
                Name               = $serviceApp.DisplayName
                ProxyName          = $proxyName
                ApplicationPool    = $serviceApp.ApplicationPool.Name
                FarmAccount        = $farmAccountName
                MySiteHostLocation = $params.MySiteHostLocation
                ProfileDBName      = $databases.ProfileDatabase.Name
                ProfileDBServer    = $databases.ProfileDatabase.NormalizedDataSource
                SocialDBName       = $databases.SocialDatabase.Name
                SocialDBServer     = $databases.SocialDatabase.NormalizedDataSource
                SyncDBName         = $databases.SynchronizationDatabase.Name
                SyncDBServer       = $databases.SynchronizationDatabase.NormalizedDataSource
                InstallAccount     = $params.InstallAccount
                EnableNetBIOS      = $serviceApp.NetBIOSDomainNamesEnabled
                NoILMUsed          = $serviceApp.NoILMUsed
                Ensure             = "Present"
            }
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

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [Parameter()]
        [System.String]
        $MySiteHostLocation,

        [Parameter()]
        [System.String]
        $ProfileDBName,

        [Parameter()]
        [System.String]
        $ProfileDBServer,

        [Parameter()]
        [System.String]
        $SocialDBName,

        [Parameter()]
        [System.String]
        $SocialDBServer,

        [Parameter()]
        [System.String]
        $SyncDBName,

        [Parameter()]
        [System.String]
        $SyncDBServer,

        [Parameter()]
        [System.Boolean]
        $EnableNetBIOS = $false,

        [Parameter()]
        [System.Boolean]
        $NoILMUsed = $false,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting user profile service application $Name"

    if ($Ensure -eq "Present")
    {
        $farmAccountName = Invoke-SPDSCCommand -Credential $InstallAccount `
                                               -Arguments $PSBoundParameters `
                                               -ScriptBlock {
            return Get-SPDSCFarmAccountName
        }

        if ($null -ne $farmAccountName)
        {
            if ($PSBoundParameters.ContainsKey("InstallAccount") -eq $true)
            {
                # InstallAccount used
                if ($InstallAccount.UserName -eq $farmAccountName)
                {
                    throw ("Specified InstallAccount ($($InstallAccount.UserName)) is the Farm " + `
                           "Account. Make sure the specified InstallAccount isn't the Farm Account " + `
                           "and try again")
                }
            }
            else
            {
                # PSDSCRunAsCredential or System
                if (-not $Env:USERNAME.Contains("$"))
                {
                    # PSDSCRunAsCredential used
                    $localaccount = "$($Env:USERDOMAIN)\$($Env:USERNAME)"
                    if ($localaccount -eq $farmAccountName)
                    {
                        throw ("Specified PSDSCRunAsCredential ($localaccount) is the Farm " + `
                               "Account. Make sure the specified PSDSCRunAsCredential isn't the " + `
                               "Farm Account and try again")
                    }
                }
            }

            # InstallAccount used
            if ($FarmAccount.UserName -ne $farmAccountName)
            {
                throw ("Specified FarmAccount ($($FarmAccount.UserName)) isn't the Farm " + `
                        "Account. Make sure the specified FarmAccount is the actual Farm " + `
                        "Account and try again")
            }
        }
        else
        {
            throw ("Unable to retrieve the Farm Account. Check if the farm exists.")
        }

        Write-Verbose -Message "Creating user profile service application $Name"

        # Add the FarmAccount to the local Administrators group, if it's not already there
        $isLocalAdmin = Test-SPDSCUserIsLocalAdmin -UserName $farmAccount.UserName

        if (!$isLocalAdmin)
        {
            Add-SPDSCUserToLocalAdmin -UserName $farmAccount.UserName

            # Cycle the Timer Service so that it picks up the local Admin token
            Restart-Service -Name "SPTimerV4"
        }

        $null = Invoke-SPDSCCommand -Credential $FarmAccount `
                                    -Arguments $PSBoundParameters `
                                    -ScriptBlock {
            $params = $args[0]

            $updateEnableNetBIOS = $false
            if ($params.ContainsKey("EnableNetBIOS"))
            {
                $updateEnableNetBIOS = $true
                $enableNetBIOS = $params.EnableNetBIOS
                $params.Remove("EnableNetBIOS") | Out-Null
            }

            $updateNoILMUsed = $false
            if ($params.ContainsKey("NoILMUsed"))
            {
                $updateNoILMUsed = $true
                $NoILMUsed = $params.NoILMUsed
                $params.Remove("NoILMUsed") | Out-Null
            }

            if ($params.ContainsKey("InstallAccount"))
            {
                $params.Remove("InstallAccount") | Out-Null
            }
            if ($params.ContainsKey("Ensure"))
            {
                $params.Remove("Ensure") | Out-Null
            }
            $params.Remove("FarmAccount") | Out-Null

            $params = Rename-SPDSCParamValue -params $params `
                                             -oldName "SyncDBName" `
                                             -newName "ProfileSyncDBName"

            $params = Rename-SPDSCParamValue -params $params `
                                             -oldName "SyncDBServer" `
                                             -newName "ProfileSyncDBServer"

            if ($params.ContainsKey("ProxyName"))
            {
                $pName = $params.ProxyName
                $params.Remove("ProxyName") | Out-Null
            }
            if ($null -eq $pName)
            {
                $pName = "$($params.Name) Proxy"
            }

            $serviceApps = Get-SPServiceApplication -Name $params.Name `
                                                    -ErrorAction SilentlyContinue
            $app = $serviceApps | Select-Object -First 1
            if ($null -eq $serviceApps)
            {
                $app = New-SPProfileServiceApplication @params
                if ($null -ne $app)
                {
                    New-SPProfileServiceApplicationProxy -Name $pName `
                                                         -ServiceApplication $app `
                                                         -DefaultProxyGroup
                }
            }

            if (($updateEnableNetBIOS -eq $true) -or ($updateNoILMUsed -eq $true))
            {
                if (($updateEnableNetBIOS -eq $true) -and `
                    ($app.NetBIOSDomainNamesEnabled -ne $enableNetBIOS))
                {
                    $app.NetBIOSDomainNamesEnabled = $enableNetBIOS
                }

                if (($updateNoILMUsed -eq $true) -and `
                    ($app.NoILMUsed -ne $NoILMUsed))
                {
                    $app.NoILMUsed = $NoILMUsed
                }
                $app.Update()
            }
        }

        # Remove the InstallAccount from the local Administrators group, if it was added above
        if (!$isLocalAdmin)
        {
            Remove-SPDSCUserToLocalAdmin -UserName $farmAccount.UserName
        }
    }

    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing user profile service application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {

            $params = $args[0]

            $app = Get-SPServiceApplication -Name $params.Name `
                    | Where-Object -FilterScript {
                        $_.GetType().FullName -eq "Microsoft.Office.Server.Administration.UserProfileApplication"
                    }

            $proxies = Get-SPServiceApplicationProxy
            foreach($proxyInstance in $proxies)
            {
                if($app.IsConnected($proxyInstance))
                {
                    $proxyInstance.Delete()
                }
            }

            Remove-SPServiceApplication -Identity $app -Confirm:$false
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

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [Parameter()]
        [System.String]
        $MySiteHostLocation,

        [Parameter()]
        [System.String]
        $ProfileDBName,

        [Parameter()]
        [System.String]
        $ProfileDBServer,

        [Parameter()]
        [System.String]
        $SocialDBName,

        [Parameter()]
        [System.String]
        $SocialDBServer,

        [Parameter()]
        [System.String]
        $SyncDBName,

        [Parameter()]
        [System.String]
        $SyncDBServer,

        [Parameter()]
        [System.Boolean]
        $EnableNetBIOS = $false,

        [Parameter()]
        [System.Boolean]
        $NoILMUsed = $false,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing for user profile service application $Name"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if($Ensure -eq "Present")
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                            -DesiredValues $PSBoundParameters `
                                            -ValuesToCheck @("Name",
                                                             "EnableNetBIOS",
                                                             "NoILMUsed",
                                                             "Ensure")
    }
    else
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                            -DesiredValues $PSBoundParameters `
                                            -ValuesToCheck @("Name", "Ensure")
    }
}

Export-ModuleMember -Function *-TargetResource
