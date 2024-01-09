# Input bindings are passed in via param block.
param($Timer)

# Add all your Azure Subscription Ids below
$subscriptionids = @"
[
    "xxxxxxxxxxxxxxxxxxxx"
]
"@ | ConvertFrom-Json

# Convert UTC to Custom Time zone. In my case, W. Central Africa Standard Time
$date = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now,"Belarus Standard Time")

foreach ($subscriptionid in $subscriptionids) {
    # Selecting Azure Sub
    Set-AzContext -SubscriptionId $Subscriptionid | Out-Null

    $CurrentSub = (Get-AzContext).Subscription.Id
        If ($CurrentSub -ne $Subscriptionid) {
            Throw "Switching to SubscriptionID: $Subscriptionid failed"
        }

    $vms = Get-AzVM -Status | Where-Object {($_.tags.Shutdown -ne $null) -and ($_.tags.StartVM -ne $null)}
    $now = $date

    foreach ($vm in $vms) {

        if ( ($vm.PowerState -eq 'VM running') -and ( $now -gt $(get-date $($vm.tags.Shutdown)) ) -and ( $now -lt $(get-date $($vm.tags.Shutdown)).AddMinutes(5) ) ) {
            Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Confirm:$false -Force
            Write-Warning "Stop VM - $($vm.Name)"
        }
        elseif ( ($vm.PowerState -eq 'VM deallocated') -and ( ($now -gt $(get-date $($vm.tags.StartVM) ) ) -and ( $now -lt $(get-date $($vm.tags.StartVM)).AddMinutes(5) ) ) ) {
            Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
            Write-Warning "Start VM - $($vm.Name)"
        }
    }

}

Write-Output $date