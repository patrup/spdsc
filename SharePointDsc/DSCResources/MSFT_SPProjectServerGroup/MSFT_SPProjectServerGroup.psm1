function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $ADGroup,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting group settings for '$Name' at '$Url'"

    if ((Get-SPDscInstalledProductVersion).FileMajorPart -lt 16)
    {
        $message = ("Support for Project Server in SharePointDsc is only valid for " + `
                "SharePoint 2016 and 2019.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("ADGroup") -eq $true -and `
        ($PSBoundParameters.ContainsKey("Members") -eq $true -or `
                $PSBoundParameters.ContainsKey("MembersToInclude") -eq $true -or `
                $PSBoundParameters.ContainsKey("MembersToExclude") -eq $true))
    {
        $message = ("Property ADGroup can not be used at the same time as Members, " + `
                "MembersToInclude or MembersToExclude")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("Members") -eq $true -and `
        ($PSBoundParameters.ContainsKey("MembersToInclude") -eq $true -or `
                $PSBoundParameters.ContainsKey("MembersToExclude") -eq $true))
    {
        $message = ("Property Members can not be used at the same time as " + `
                "MembersToInclude or MembersToExclude")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $PSScriptRoot) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $scriptRoot = $args[2]

        if ((Get-SPProjectPermissionMode -Url $params.Url) -ne "ProjectServer")
        {
            $message = ("SPProjectServerGroup is design for Project Server permissions " + `
                    "mode only, and this site is set to SharePoint mode")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $modulePath = "..\..\Modules\SharePointDsc.ProjectServerConnector\SharePointDsc.ProjectServerConnector.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

        $webAppUrl = (Get-SPSite -Identity $params.Url).WebApplication.Url
        $useKerberos = -not (Get-SPAuthenticationProvider -WebApplication $webAppUrl -Zone Default).DisableKerberos
        $securityService = New-SPDscProjectServerWebService -PwaUrl $params.Url `
            -EndpointName Security `
            -UseKerberos:$useKerberos

        $script:groupDataSet = $null
        Use-SPDscProjectServerWebService -Service $securityService -ScriptBlock {
            $groupInfo = $securityService.ReadGroupList().SecurityGroups | Where-Object -FilterScript {
                $_.WSEC_GRP_NAME -eq $params.Name
            }

            if ($null -ne $groupInfo)
            {
                $script:groupDataSet = $securityService.ReadGroup($groupInfo.WSEC_GRP_UID)
            }
        }

        if ($null -eq $script:groupDataSet)
        {
            return @{
                Url              = $params.Url
                Name             = $params.Name
                Description      = ""
                ADGroup          = ""
                Members          = $null
                MembersToInclude = $null
                MembersToExclude = $null
                Ensure           = "Absent"
            }
        }
        else
        {
            $adGroup = ""
            if ($script:groupDataSet.SecurityGroups.WSEC_GRP_AD_GUID.GetType() -ne [System.DBNull])
            {
                $adGroup = Convert-SPDscADGroupIDToName -GroupId $script:groupDataSet.SecurityGroups.WSEC_GRP_AD_GUID
            }

            $groupMembers = @()

            if ($adGroup -eq "")
            {
                # No AD group is set, check for individual members
                $script:groupDataSet.GroupMembers.Rows | ForEach-Object -Process {
                    $groupMembers += Get-SPDscProjectServerResourceName -ResourceId $_["RES_UID"] -PwaUrl $params.Url
                }
            }

            for ($i = 0; $i -lt $groupMembers.Count; $i++)
            {
                if ($groupMembers[$i].Contains(":0") -eq $true)
                {
                    $realUserName = New-SPClaimsPrincipal -Identity $groupMembers[$i] `
                        -IdentityType EncodedClaim
                    $groupMembers[$i] = $realUserName.Value
                }
            }

            return @{
                Url              = $params.Url
                Name             = $script:groupDataSet.SecurityGroups.WSEC_GRP_NAME
                Description      = $script:groupDataSet.SecurityGroups.WSEC_GRP_DESC
                ADGroup          = $adGroup
                Members          = $groupMembers
                MembersToInclude = $null
                MembersToExclude = $null
                Ensure           = "Present"
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
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $ADGroup,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting group settings for '$Name' at '$Url'"

    $currentSettings = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present")
    {
        Invoke-SPDscCommand -Arguments @($PSBoundParameters, $PSScriptRoot, $currentSettings) `
            -ScriptBlock {

            $params = $args[0]
            $scriptRoot = $args[1]
            $currentSettings = $args[2]

            $modulePath = "..\..\Modules\SharePointDsc.ProjectServerConnector\SharePointDsc.ProjectServerConnector.psm1"
            Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

            $webAppUrl = (Get-SPSite -Identity $params.Url).WebApplication.Url
            $useKerberos = -not (Get-SPAuthenticationProvider -WebApplication $webAppUrl -Zone Default).DisableKerberos
            $securityService = New-SPDscProjectServerWebService -PwaUrl $params.Url `
                -EndpointName Security `
                -UseKerberos:$useKerberos

            Use-SPDscProjectServerWebService -Service $securityService -ScriptBlock {
                $groupInfo = $securityService.ReadGroupList().SecurityGroups | Where-Object -FilterScript {
                    $_.WSEC_GRP_NAME -eq $params.Name
                }

                if ($null -eq $groupInfo)
                {
                    # Create a new group with jsut a name so it can be updated with the properties later
                    $newGroupDS = [SvcSecurity.SecurityGroupsDataSet]::new()
                    $newGroup = $newGroupDS.SecurityGroups.NewSecurityGroupsRow()
                    $newGroup.WSEC_GRP_NAME = $params.Name
                    $newGroup.WSEC_GRP_UID = New-Guid
                    $newGroupDS.SecurityGroups.AddSecurityGroupsRow($newGroup)
                    $securityService.CreateGroups($newGroupDS)

                    $groupInfo = $securityService.ReadGroupList().SecurityGroups | Where-Object -FilterScript {
                        $_.WSEC_GRP_NAME -eq $params.Name
                    }
                }

                # Update the existing group
                $groupDS = $securityService.ReadGroup($groupInfo.WSEC_GRP_UID)
                $group = $groupDS.SecurityGroups.FindByWSEC_GRP_UID($groupInfo.WSEC_GRP_UID)

                $group.WSEC_GRP_NAME = $params.Name
                if ($params.ContainsKey("Description") -eq $true)
                {
                    $group.WSEC_GRP_DESC = $params.Description
                }
                if ($params.ContainsKey("ADGroup") -eq $true)
                {
                    $group.WSEC_GRP_AD_GUID = (Convert-SPDscADGroupNameToID -GroupName $params.ADGroup)
                    $group.WSEC_GRP_AD_GROUP = $params.ADGroup.Split('\')[1]
                }
                if ($params.ContainsKey("Members") -eq $true)
                {
                    $currentSettings.Members | ForEach-Object -Process {
                        if ($params.Members -notcontains $_)
                        {
                            $resourceId = Get-SPDscProjectServerResourceId -ResourceName $_ -PWaUrl $params.Url
                            $rowToDrop = $groupDS.GroupMembers.FindByRES_UIDWSEC_GRP_UID($resourceId, $groupInfo.WSEC_GRP_UID)
                            $rowToDrop.Delete()
                        }
                    }
                    $params.Members | ForEach-Object -Process {
                        if ($currentSettings.Members -notcontains $_)
                        {
                            $resourceId = Get-SPDscProjectServerResourceId -ResourceName $_ -PWaUrl $params.Url
                            $row = $groupDS.GroupMembers.NewGroupMembersRow()
                            $row.WSEC_GRP_UID = $groupInfo.WSEC_GRP_UID
                            $row.RES_UID = $resourceId
                            $groupDS.GroupMembers.AddGroupMembersRow($row)
                        }
                    }
                }
                if ($params.ContainsKey("MembersToInclude") -eq $true)
                {
                    $params.MembersToInclude | ForEach-Object -Process {
                        if ($currentSettings.Members -notcontains $_)
                        {
                            $resourceId = Get-SPDscProjectServerResourceId -ResourceName $_ -PWaUrl $params.Url
                            $row = $groupDS.GroupMembers.NewGroupMembersRow()
                            $row.WSEC_GRP_UID = $groupInfo.WSEC_GRP_UID
                            $row.RES_UID = $resourceId
                            $groupDS.GroupMembers.AddGroupMembersRow($row)
                        }
                    }
                }

                if ($params.ContainsKey("MembersToExclude") -eq $true)
                {
                    $params.MembersToExclude | ForEach-Object -Process {
                        if ($currentSettings.Members -contains $_)
                        {
                            $resourceId = Get-SPDscProjectServerResourceId -ResourceName $_ -PWaUrl $params.Url
                            $rowToDrop = $groupDS.GroupMembers.FindByRES_UIDWSEC_GRP_UID($resourceId, $groupInfo.WSEC_GRP_UID)
                            $rowToDrop.Delete()
                        }
                    }
                }

                $securityService.SetGroups($groupDS)
            }
        }
    }
    else
    {
        Invoke-SPDscCommand -Arguments @($PSBoundParameters, $PSScriptRoot) `
            -ScriptBlock {

            $params = $args[0]
            $scriptRoot = $args[1]

            $modulePath = "..\..\Modules\SharePointDsc.ProjectServerConnector\SharePointDsc.ProjectServerConnector.psm1"
            Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

            $webAppUrl = (Get-SPSite -Identity $params.Url).WebApplication.Url
            $useKerberos = -not (Get-SPAuthenticationProvider -WebApplication $webAppUrl -Zone Default).DisableKerberos
            $securityService = New-SPDscProjectServerWebService -PwaUrl $params.Url `
                -EndpointName Security `
                -UseKerberos:$useKerberos

            Use-SPDscProjectServerWebService -Service $securityService -ScriptBlock {
                $groupInfo = $securityService.ReadGroupList().SecurityGroups | Where-Object -FilterScript {
                    $_.WSEC_GRP_NAME -eq $params.Name
                }

                if ($null -ne $groupInfo)
                {
                    # Remove the group
                    $securityService.DeleteGroups($groupInfo.WSEC_GRP_UID)
                }
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
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $ADGroup,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing group settings for '$Name' at '$Url'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($PSBoundParameters.ContainsKey("Members") -eq $true)
    {
        $membersMatch = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Members")

        if ($membersMatch -eq $false)
        {
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($PSBoundParameters.ContainsKey("MembersToInclude") -eq $true)
    {
        $missingMembers = $false
        $MembersToInclude | ForEach-Object -Process {
            if ($currentValues.Members -notcontains $_)
            {
                Write-Verbose -Message "'$_' is not in the members list, but should be"
                $missingMembers = $true
            }
        }
        if ($missingMembers -eq $true)
        {
            $message = "Users from the MembersToInclude property are not included"
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($PSBoundParameters.ContainsKey("MembersToExclude") -eq $true)
    {
        $extraMembers = $false
        $MembersToExclude | ForEach-Object -Process {
            if ($currentValues.Members -contains $_)
            {
                Write-Verbose -Message "'$_' is in the members list, but should not be"
                $extraMembers = $true
            }
        }
        if ($extraMembers -eq $true)
        {
            $message = "Users from the MembersToExclude property are included"
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @(
        "Name",
        "Description",
        "ADGroup",
        "Ensure"
    )

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
