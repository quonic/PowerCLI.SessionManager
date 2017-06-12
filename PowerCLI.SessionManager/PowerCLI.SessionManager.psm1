Function Get-ViSession {
    <#
    .SYNOPSIS
    Lists vCenter Sessions.

    .DESCRIPTION
    Lists all connected vCenter Sessions.

    .EXAMPLE
    PS C:\> Get-VISession

    .EXAMPLE
    PS C:\> Get-VISession | Where { $_.IdleMinutes -gt 5 }
    #>
    $SessionMgr = Get-View $DefaultViserver.ExtensionData.Client.ServiceContent.SessionManager
    $script:AllSessions = @()
    $SessionMgr.SessionList | ForEach-Object {
        $Session = New-Object -TypeName PSObject -Property @{
            Key            = $_.Key
            UserName       = $_.UserName
            FullName       = $_.FullName
            LoginTime      = ($_.LoginTime).ToLocalTime()
            LastActiveTime = ($_.LastActiveTime).ToLocalTime()

        }
        If ($_.Key -eq $SessionMgr.CurrentSession.Key) {
            $Session | Add-Member -MemberType NoteProperty -Name Status -Value "Current Session"
        }
        Else {
            $Session | Add-Member -MemberType NoteProperty -Name Status -Value "Idle"
        }
        $Session | Add-Member -MemberType NoteProperty -Name IdleMinutes -Value ([Math]::Round(((Get-Date) - ($_.LastActiveTime).ToLocalTime()).TotalMinutes))
        $script:AllSessions += $Session
    }
    $script:AllSessions
}

Function Disconnect-ViSession {
    <#
    .SYNOPSIS
    Disconnects a connected vCenter Session.

    .DESCRIPTION
    Disconnects a open connected vCenter Session.

    .PARAMETER  SessionList
    A session or a list of sessions to disconnect.

    .EXAMPLE
    PS C:\> Get-VISession | Where { $_.IdleMinutes -gt 5 } | Disconnect-ViSession

    .EXAMPLE
    PS C:\> Get-VISession | Where { $_.Username -eq “User19” } | Disconnect-ViSession
    #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline = $true)]
        $SessionList
    )
    Process {
        $SessionMgr = Get-View $DefaultViserver.ExtensionData.Client.ServiceContent.SessionManager
        $SessionList | ForEach-Object {
            "Disconnecting Session for $($_.Username) which has been active since $($_.LoginTime)"
            $SessionMgr.TerminateSession($_.Key)
        }
    }
}
Export-ModuleMember -Function 'Get-ViSession','Disconnect-ViSession'