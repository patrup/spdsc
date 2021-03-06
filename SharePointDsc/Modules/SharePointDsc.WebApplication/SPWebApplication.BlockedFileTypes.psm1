function Get-SPDscWebApplicationBlockedFileTypeConfig
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        $WebApplication
    )
    $result = @()
    $WebApplication.BlockedFileExtensions | ForEach-Object -Process {
        $result += $_
    }
    $returnval = @{
        Blocked = $result
    }

    return $returnval
}

function Set-SPDscWebApplicationBlockedFileTypeConfig
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        $WebApplication,

        [Parameter(Mandatory = $true)]
        $Settings
    )

    if (($Settings.ContainsKey("Blocked") -eq $true) `
            -and (($Settings.ContainsKey("EnsureBlocked") -eq $true) `
                -or ($Settings.ContainsKey("EnsureAllowed") -eq $true)))
    {
        $message = ("Blocked file types must use either the 'blocked' property or the " + `
                "'EnsureBlocked' and/or 'EnsureAllowed' properties, but not both.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($Settings.ContainsKey("Blocked") -eq $false) `
            -and ($Settings.ContainsKey("EnsureBlocked") -eq $false) `
            -and ($Settings.ContainsKey("EnsureAllowed") -eq $false))
    {
        $message = ("Blocked file types must specify at least one property (either 'Blocked, " + `
                "'EnsureBlocked' or 'EnsureAllowed')")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($Settings.ContainsKey("Blocked") -eq $true)
    {
        $WebApplication.BlockedFileExtensions.Clear();
        $Settings.Blocked | ForEach-Object -Process {
            $WebApplication.BlockedFileExtensions.Add($_.ToLower());
        }
    }

    if ($Settings.ContainsKey("EnsureBlocked") -eq $true)
    {
        $Settings.EnsureBlocked | ForEach-Object -Process {
            if (!$WebApplication.BlockedFileExtensions.Contains($_.ToLower()))
            {
                $WebApplication.BlockedFileExtensions.Add($_.ToLower());
            }
        }
    }

    if ($Settings.ContainsKey("EnsureAllowed") -eq $true)
    {
        $Settings.EnsureAllowed | ForEach-Object -Process {
            if ($WebApplication.BlockedFileExtensions.Contains($_.ToLower()))
            {
                $WebApplication.BlockedFileExtensions.Remove($_.ToLower());
            }
        }
    }
}

function Test-SPDscWebApplicationBlockedFileTypeConfig
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        $CurrentSettings,

        [Parameter(Mandatory = $true)]
        $DesiredSettings,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Source
    )

    $relPath = "..\..\Modules\SharePointDsc.Util\SharePointDsc.Util.psm1"
    Import-Module (Join-Path $PSScriptRoot $relPath -Resolve)

    if (($DesiredSettings.ContainsKey("Blocked") -eq $true) `
            -and (($DesiredSettings.ContainsKey("EnsureBlocked") -eq $true) `
                -or ($DesiredSettings.ContainsKey("EnsureAllowed") -eq $true)))
    {
        $message = ("Blocked file types must use either the 'blocked' property or the " + `
                "'EnsureBlocked' and/or 'EnsureAllowed' properties, but not both.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($DesiredSettings.ContainsKey("Blocked") -eq $false) `
            -and ($DesiredSettings.ContainsKey("EnsureBlocked") -eq $false) `
            -and ($DesiredSettings.ContainsKey("EnsureAllowed") -eq $false))
    {
        $message = ("Blocked file types must specify at least one property (either 'Blocked, " + `
                "'EnsureBlocked' or 'EnsureAllowed')")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($DesiredSettings.ContainsKey("Blocked") -eq $true)
    {
        $compareResult = Compare-Object -ReferenceObject $CurrentSettings.Blocked `
            -DifferenceObject $DesiredSettings.Blocked
        if ($null -eq $compareResult)
        {
            return $true
        }
        else
        {
            $message = ("The parameter Blocked does not match the desired state. " + `
                    "Actual: $($CurrentSettings.Blocked). Desired: $($DesiredSettings.Blocked)")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $Source

            return $false
        }
    }

    if ($DesiredSettings.ContainsKey("EnsureBlocked") -eq $true)
    {
        $itemsToAdd = Compare-Object -ReferenceObject $CurrentSettings.Blocked `
            -DifferenceObject $DesiredSettings.EnsureBlocked | Where-Object {
            $_.SideIndicator -eq "=>"
        }
        if ($null -ne $itemsToAdd)
        {
            $message = ("The parameter EnsureBlocked does not match the desired state. " + `
                    "Actual: $($CurrentSettings.Blocked). Desired: $($DesiredSettings.EnsureBlocked)")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $Source

            return $false
        }
    }

    if ($DesiredSettings.ContainsKey("EnsureAllowed") -eq $true)
    {
        $itemsToRemove = Compare-Object -ReferenceObject $CurrentSettings.Blocked `
            -DifferenceObject $DesiredSettings.EnsureAllowed `
            -ExcludeDifferent -IncludeEqual
        if ($null -ne $itemsToRemove)
        {
            $message = ("The parameter EnsureAllowed does not match the desired state. " + `
                    "Actual: $($CurrentSettings.Blocked). Desired: $($DesiredSettings.EnsureAllowed)")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $Source

            return $false
        }
    }
    return $true
}
