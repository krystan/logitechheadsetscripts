# List PRO X 2 devices by class and show the INF used
Get-PnpDevice -PresentOnly |
Where-Object { $_.FriendlyName -match 'PRO X 2|Logitech.*PRO X 2' } |
ForEach-Object {
    $inf = (Get-PnpDeviceProperty -InstanceId $_.InstanceId `
            -KeyName 'DEVPKEY_Device_DriverInfPath' -ErrorAction SilentlyContinue).Data
    [pscustomobject]@{
        Class        = $_.Class
        FriendlyName = $_.FriendlyName
        InstanceId   = $_.InstanceId
        InfName      = $inf
    }
} | Sort-Object Class, FriendlyName | Format-Table -Auto
