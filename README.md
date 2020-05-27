# wvd-Spring-Scaling

Taking the Fall 2019 scaling scripts are rewriting them to fit Spring 2020 WVD scaling automation

***Should be completed by 5/15/2020***

Follow along with the MS Docs page, just substitute these .ps1 files.

https://docs.microsoft.com/en-us/azure/virtual-desktop/virtual-desktop-fall-2019/set-up-scaling-script


***Instructions***

***Create an Azure Automation account***
--First, you'll need an Azure Automation account to run the PowerShell runbook. Here's how to set up your account:

1) Open Windows PowerShell as an administrator.

2) Run the following cmdlet to sign in to your Azure Account.

Login-AzAccount

***Note***

***Your account must have contributor rights on the Azure subscription that you want to deploy the scaling tool on.***

3) Run the following cmdlet to download the script for creating the Azure Automation account:

		Set-Location -Path "c:\temp"
		$uri = "https://raw.githubusercontent.com/Greyt3ch/WVD-Spring2020-Scaling/createazureautomationaccount.ps1"
		Invoke-WebRequest -Uri $uri -OutFile ".\createazureautomationaccount.ps1"

4) Run the following cmdlet to execute the script and create the Azure Automation account:

		.\createazureautomationaccount.ps1 -SubscriptionID <azuresubscriptionid> -ResourceGroupName <resourcegroupname> -AutomationAccountName <name of automation account> -Location "Azure region for deployment"

5) The cmdlet's output will include a webhook URI. Make sure to keep a record of the URI because you'll use it as a parameter when you set up the execution schedule for the Azure Logic apps.

6) After you've set up your Azure Automation account, sign in to your Azure subscription and check to make sure your Azure Automation account and the relevant runbook have appeared in your specified resource group, as shown in the following image:

***Note***

***To check if your webhook is where it should be, select the name of your runbook. Next, go to your runbook's Resources section and select Webhooks.***

***Create an Azure Automation Run As account***

Now that you have an Azure Automation account, you'll also need to create an Azure Automation Run As account to access your Azure resources.

An Azure Automation Run As account provides authentication for managing resources in Azure with the Azure cmdlets. When you create a Run As account, it creates a new service principal user in Azure Active Directory and assigns the Contributor role to the service principal user at the subscription level, the Azure Run As Account is a great way to authenticate securely with certificates and a service principal name without needing to store a username and password in a credential object. To learn more about Run As authentication, see Limit Run As account permissions.

Any user who's a member of the Subscription Admins role and coadministrator of the subscription can create a Run As account by following the next section's instructions.

To create a Run As account in your Azure account:

	1) In the Azure portal, select ***All services***. In the list of resources, enter and select Automation Accounts.

	2) On the Automation Accounts page, select the name of your Automation account.

	3) In the pane on the left side of the window, select Run As Accounts under the Account Settings section.

	4) Select Azure Run As Account. When the Add Azure Run As Account pane appears, review the overview information, and then select 
	   Create to start the account creation process.

	5) Wait a few minutes for Azure to create the Run As account. You can track the creation progress in the menu under Notifications.

	6) When the process finishes, it will create an asset named AzureRunAsConnection in the specified Automation account. The connection  		asset holds the application ID, tenant ID, subscription ID, and certificate thumbprint. Remember the application ID, because 		  you'll use it later.
	
***Create a role assignment in Windows Virtual Desktop***

1) Add the "Run As Account" as a 'Contributor' to the Resource Group that contains both the:
	-Host Pool
	-Session Hosts


***Create the Azure Logic App and execution schedule***
Finally, you'll need to create the Azure Logic App and set up an execution schedule for your new scaling tool.

1) Open Windows PowerShell as an Administrator

2) Run the following cmdlet to sign in to your Azure Account.

		Login-AzAccount

3) Run the following cmdlet to download the createazurelogicapp.ps1 script file on your local machine.

		Set-Location -Path "c:\temp"
		$uri = "https://raw.githubusercontent.com/Greyt3ch/WVD-Spring2020-Scaling/createazurelogicapp-SP2020.ps1"
		Invoke-WebRequest -Uri $uri -OutFile ".\createazurelogicapp.ps1"

Run the following cmdlet to sign into Windows Virtual Desktop with an account that has RDS Owner or RDS Contributor permissions.


Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"
Run the following PowerShell script to create the Azure Logic app and execution schedule.

PowerShell

Copy
$aadTenantId = (Get-AzContext).Tenant.Id

$azureSubscription = Get-AzSubscription | Out-GridView -PassThru -Title "Select your Azure Subscription"
Select-AzSubscription -Subscription $azureSubscription.Id
$subscriptionId = $azureSubscription.Id

$resourceGroup = Get-AzResourceGroup | Out-GridView -PassThru -Title "Select the resource group for the new Azure Logic App"
$resourceGroupName = $resourceGroup.ResourceGroupName
$location = $resourceGroup.Location

$wvdTenant = Get-RdsTenant | Out-GridView -PassThru -Title "Select your WVD tenant"
$tenantName = $wvdTenant.TenantName

$wvdHostpool = Get-RdsHostPool -TenantName $wvdTenant.TenantName | Out-GridView -PassThru -Title "Select the host pool you'd like to scale"
$hostPoolName = $wvdHostpool.HostPoolName

$recurrenceInterval = Read-Host -Prompt "Enter how often you'd like the job to run in minutes, e.g. '15'"
$beginPeakTime = Read-Host -Prompt "Enter the start time for peak hours in local time, e.g. 9:00"
$endPeakTime = Read-Host -Prompt "Enter the end time for peak hours in local time, e.g. 18:00"
$timeDifference = Read-Host -Prompt "Enter the time difference between local time and UTC in hours, e.g. +5:30"
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

.\createazurelogicapp.ps1 -ResourceGroupName $resourceGroupName `
  -AADTenantID $aadTenantId `
  -SubscriptionID $subscriptionId `
  -TenantName $tenantName `
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
After you run the script, the Logic App should appear in a resource group, as shown in the following image.

An image of the overview page for an example Azure Logic App.

To make changes to the execution schedule, such as changing the recurrence interval or time zone, go to the Autoscale scheduler and select Edit to go to the Logic Apps Designer.

An image of the Logic Apps Designer. The Recurrence and Webhook menus that let the user edit recurrence times and the webhook file are open.
