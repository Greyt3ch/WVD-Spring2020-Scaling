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


