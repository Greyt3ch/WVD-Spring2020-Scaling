$aadTenantId = (Get-AzContext).Tenant.Id

$azureSubscription = Get-AzSubscription | Out-GridView -PassThru -Title "Select your Azure Subscription"
Select-AzSubscription -Subscription $azureSubscription.Id
$subscriptionId = $azureSubscription.Id

$resourceGroup = Get-AzResourceGroup | Out-GridView -PassThru -Title "Select the resource group for the new Azure Logic App"
$resourceGroupName = $resourceGroup.ResourceGroupName
$location = $resourceGroup.Location


$hostPoolName = Read-Host -Prompt "Enter Host Pool Name"
$recurrenceInterval = Read-Host -Prompt "Enter how often you'd like the job to run in minutes, e.g. '15'"
$beginPeakTime = Read-Host -Prompt "Enter the start time for peak hours in local time, e.g. 7:00"
$endPeakTime = Read-Host -Prompt "Enter the end time for peak hours in local time, e.g. 18:00"
$timeDifference = Read-Host -Prompt "Enter the time difference between local time and UTC in hours, e.g. -5:00"
$sessionThresholdPerCPU = Read-Host -Prompt "Enter the maximum number of sessions per CPU that will be used as a threshold to determine when new session host VMs need to be started during peak hours"
$minimumNumberOfRdsh = Read-Host -Prompt "Enter the minimum number of session host VMs to keep running during off-peak hours"
$limitSecondsToForceLogOffUser = Read-Host -Prompt "Enter the number of seconds to wait before automatically signing out users. If set to 0, users will be signed out immediately"
$logOffMessageTitle = Read-Host -Prompt "Enter the title of the message sent to the user before they are forced to sign out"
$logOffMessageBody = Read-Host -Prompt "Enter the body of the message sent to the user before they are forced to sign out"

$automationAccount = Get-AzAutomationAccount -ResourceGroupName $resourceGroup.ResourceGroupName | Out-GridView -PassThru
$automationAccountName = $automationAccount.AutomationAccountName
$automationAccountConnection = Get-AzAutomationConnection -ResourceGroupName $resourceGroup.ResourceGroupName -AutomationAccountName $automationAccount.AutomationAccountName | Out-GridView -PassThru -Title "Select the Azure RunAs connection asset"
$connectionAssetName = $automationAccountConnection.Name

$webHookURI = Read-Host -Prompt "Enter the URI of the WebHook returned by when you created the Azure Automation Account"
$maintenanceTagName = Read-Host -Prompt "Enter the name of the Tag associated with VMs you don't want to be managed by this scaling tool"

.\createazurelogicapp-SP2020.ps1 -ResourceGroupName $resourceGroupName `
  -AADTenantID $aadTenantId `
  -SubscriptionID $subscriptionId `
  -HostPoolName $hostPoolName `
  -RecurrenceInterval $recurrenceInterval `
  -BeginPeakTime $beginPeakTime `
  -EndPeakTime $endPeakTime `
  -TimeDifference $timeDifference `
  -SessionThresholdPerCPU $sessionThresholdPerCPU `
  -MinimumNumberOfRDSH $minimumNumberOfRdsh `
  -LimitSecondsToForceLogOffUser $limitSecondsToForceLogOffUser `
  -LogOffMessageTitle $logOffMessageTitle `
  -LogOffMessageBody $logOffMessageBody `
  -Location $location `
  -ConnectionAssetName $connectionAssetName `
  -WebHookURI $webHookURI `
  -AutomationAccountName $automationAccountName `
  -MaintenanceTagName $maintenanceTagName