param(
	[Parameter(mandatory = $false)]
	[object]$WebHookData
)
# If runbook was called from Webhook, WebhookData will not be null.
#testing

if ($WebHookData -eq "test") {
    $testrun = $true
    Write-Output "'test' WebHookData parameter passed."
    $WebHookData = '{"WebhookName":"WVDAutoScaleWebhook","RequestBody":"{\"AADTenantId\":\"28cda4fd-6e37-400c-8675-37c037532724\",\"AutomationAccountName\":\"wvdscaleautomation\",\"BeginPeakTime\":\"7:00\",\"CallbackUrl\":\"https://prod-06.northcentralus.logic.azure.com/workflows/fa46a002026042ba8f3d7f7deb96bc3e/runs/08586116627161303041247027697CU02/actions/HTTP_Webhook/run?api-version=2016-06-01&sp=%2Fruns%2F08586116627161303041247027697CU02%2Factions%2FHTTP_Webhook%2Frun%2C%2Fruns%2F08586116627161303041247027697CU02%2Factions%2FHTTP_Webhook%2Fread&sv=1.0&sig=8SA6d4-qozEz24LC35rQpLT3nnNPMXNfxUE0zFb_FSE\",\"ConnectionAssetName\":\"AzureRunAsConnection\",\"EndPeakTime\":\"23:00\",\"HostPoolName\":\"WIN10-STD\",\"LimitSecondsToForceLogOffUser\":300,\"LogAnalyticsPrimaryKey\":\"\",\"LogAnalyticsWorkspaceId\":\"\",\"LogOffMessageBody\":\"\\\"Please SAVE your work, logoff, and then log back in\\\"\",\"LogOffMessageTitle\":\"\\\"Auto-Scaling of Virtual Dekstop\\\"\",\"MaintenanceTagName\":\"WVDNOSCALE\",\"MinimumNumberOfRDSH\":1,\"ResourceGroupName\":\"CLHC-RG-PROD-WVD\",\"SessionThresholdPerCPU\":\".25\",\"TimeDifference\":\"-5:00\",\"subscriptionid\":\"d95fa5d8-0b50-430c-8611-72318cf74228\"}","RequestHeader":{"Connection":"Keep-Alive","Accept-Encoding":"gzip","Accept-Language":"en","Host":"s6events.azure-automation.net","User-Agent":"azure-logic-apps/1.0","x-ms-workflow-id":"fa46a002026042ba8f3d7f7deb96bc3e","x-ms-workflow-version":"08586116627207140741","x-ms-workflow-name":"WIN10-STD_Autoscale_Scheduler","x-ms-workflow-system-id":"/locations/northcentralus/scaleunits/prod-06/workflows/fa46a002026042ba8f3d7f7deb96bc3e","x-ms-workflow-run-id":"08586116627161303041247027697CU02","x-ms-workflow-run-tracking-id":"82bb603f-5363-45e3-a2cb-91d2b4fc48a1","x-ms-workflow-operation-name":"HTTP_Webhook","x-ms-execution-location":"northcentralus","x-ms-workflow-subscription-id":"d95fa5d8-0b50-430c-8611-72318cf74228","x-ms-workflow-resourcegroup-name":"CLHC-RG-PROD-WVD","x-ms-tracking-id":"66897342-6a3e-4389-8b3e-83f7f207b4c4","x-ms-correlation-id":"66897342-6a3e-4389-8b3e-83f7f207b4c4","x-ms-client-request-id":"66897342-6a3e-4389-8b3e-83f7f207b4c4","x-ms-client-tracking-id":"08586116627161303041247027697CU02","x-ms-action-tracking-id":"cfecb523-102d-4cf5-8d10-c743eabb420d","x-ms-activity-vector":"IN.0R.IN.1K"}}'
    $WebHookData = $WebHookData | ConvertFrom-Json
    # Collect properties of WebhookData
	$WebhookName = $WebHookData.WebhookName
	$WebhookHeaders = $WebHookData.RequestHeader
	$WebhookBody = $WebHookData.RequestBody | ConvertFrom-Json
}

if ($WebHookData -ne 'test') {
Write-Output "WebHookData found."
	# Collect properties of WebhookData
	$WebhookName = $WebHookData.WebhookName
	$WebhookHeaders = $WebHookData.RequestHeader
	$WebhookBody = $WebHookData.RequestBody
    

	# Collect individual headers. Input converted from JSON.
    Write-Output "WebHookData found. Converting from JSON"
	$From = $WebhookHeaders.From
	$Input = (ConvertFrom-Json -InputObject $WebHookBody)
}
else
{
    Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop

}
if (!$testrun)
{
$CallbackUrl = $Input.CallbackUrl
}
$AADTenantId = $Input.AADTenantId
$SubscriptionID = $Input.SubscriptionID
#$TenantGroupName = $Input.TenantGroupName
$ResourceGroupName = $Input.ResourceGroupName
#$TenantName = $Input.TenantName
$HostpoolName = $Input.hostpoolname
$BeginPeakTime = $Input.BeginPeakTime
$EndPeakTime = $Input.EndPeakTime
$TimeDifference = $Input.TimeDifference
$SessionThresholdPerCPU = $Input.SessionThresholdPerCPU
$MinimumNumberOfRDSH = $Input.MinimumNumberOfRDSH
$LimitSecondsToForceLogOffUser = $Input.LimitSecondsToForceLogOffUser
$LogOffMessageTitle = $Input.LogOffMessageTitle
$LogOffMessageBody = $Input.LogOffMessageBody
$MaintenanceTagName = $Input.MaintenanceTagName
$LogAnalyticsWorkspaceId = $Input.LogAnalyticsWorkspaceId
$LogAnalyticsPrimaryKey = $Input.LogAnalyticsPrimaryKey
#$RDBrokerURL = $Input.RDBrokerURL
$AutomationAccountName = $Input.AutomationAccountName
$ConnectionAssetName = $Input.ConnectionAssetName

if ($CallbackUrl) {
Write-Output "CallbackUrl for this request is $CallbackUrl."

}
elseif ((!$testrun) -and (!$CallbackUrl))
{
    Write-Error -Message 'No callback url was provided. This can lead to a long running logic app worker process. Stopping.' -ErrorAction stop

}

Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Function to convert from UTC to Local time
function Convert-UTCtoLocalTime
{
	param(
		$TimeDifferenceInHours
	)

	$UniversalTime = (Get-Date).ToUniversalTime()
	$TimeDifferenceMinutes = 0
	if ($TimeDifferenceInHours -match ":") {
		$TimeDifferenceHours = $TimeDifferenceInHours.Split(":")[0]
		$TimeDifferenceMinutes = $TimeDifferenceInHours.Split(":")[1]
	}
	else {
		$TimeDifferenceHours = $TimeDifferenceInHours
	}
	#Azure is using UTC time, justify it to the local time
	$ConvertedTime = $UniversalTime.AddHours($TimeDifferenceHours).AddMinutes($TimeDifferenceMinutes)
	return $ConvertedTime
}
# With workspace
<# if ($LogAnalyticsWorkspaceId -and $LogAnalyticsPrimaryKey)
{
	# Function for to add logs to log analytics workspace
	function Add-LogEntry
	{
		param(
			[Object]$LogMessageObj,
			[string]$LogAnalyticsWorkspaceId,
			[string]$LogAnalyticsPrimaryKey,
			[string]$LogType,
			$TimeDifferenceInHours
		)

		if ($LogAnalyticsWorkspaceId -ne $null) {

			foreach ($Key in $LogMessage.Keys) {
				switch ($Key.substring($Key.Length - 2)) {
					'_s' { $sep = '"'; $trim = $Key.Length - 2 }
					'_t' { $sep = '"'; $trim = $Key.Length - 2 }
					'_b' { $sep = ''; $trim = $Key.Length - 2 }
					'_d' { $sep = ''; $trim = $Key.Length - 2 }
					'_g' { $sep = '"'; $trim = $Key.Length - 2 }
					default { $sep = '"'; $trim = $Key.Length }
				}
				$LogData = $LogData + '"' + $Key.substring(0,$trim) + '":' + $sep + $LogMessageObj.Item($Key) + $sep + ','
			}
			$TimeStamp = Convert-UTCtoLocalTime -TimeDifferenceInHours $TimeDifferenceInHours
			$LogData = $LogData + '"TimeStamp":"' + $timestamp + '"'

			#Write-Verbose "LogData: $($LogData)"
			$json = "{$($LogData)}"

			$PostResult = Send-OMSAPIIngestionFile -customerId $LogAnalyticsWorkspaceId -sharedKey $LogAnalyticsPrimaryKey -Body "$json" -logType $LogType -TimeStampField "TimeStamp"
			#Write-Verbose "PostResult: $($PostResult)"
			if ($PostResult -ne "Accepted") {
				Write-Error "Error posting to OMS - $PostResult"
			}
		}
	}

	# Collect the credentials from Azure Automation Account Assets
	$Connection = Get-AutomationConnection -Name $ConnectionAssetName

	# Authenticating to Azure
	Clear-AzContext -Force
	$AZAuthentication = Connect-AzAccount -ApplicationId $Connection.ApplicationId -TenantId $AADTenantId -CertificateThumbprint $Connection.CertificateThumbprint -ServicePrincipal
	if ($AZAuthentication -eq $null) {
		Write-Output "Failed to authenticate Azure: $($_.exception.message)"
		$LogMessage = @{ hostpoolName_s = $HostpoolName; logmessage_s = "Failed to authenticate Azure: $($_.exception.message)" }
		Add-LogEntry -LogMessageObj $LogMessage -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId -LogAnalyticsPrimaryKey $LogAnalyticsPrimaryKey -logType "WVDTenantScale_CL" -TimeDifferenceInHours $TimeDifference
		exit
	} else {
		$AzObj = $AZAuthentication | Out-String
		Write-Output "Authenticating as service principal for Azure. Result: `n$AzObj"
		$LogMessage = @{ hostpoolName_s = $HostpoolName; logmessage_s = "Authenticating as service principal for Azure. Result: `n$AzObj" }
		Add-LogEntry -LogMessageObj $LogMessage -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId -LogAnalyticsPrimaryKey $LogAnalyticsPrimaryKey -logType "WVDTenantScale_CL" -TimeDifferenceInHours $TimeDifference
	}
	# Set the Azure context with Subscription
	$AzContext = Set-AzContext -SubscriptionId $SubscriptionID
	if ($AzContext -eq $null) {
		Write-Error "Please provide a valid subscription"
		exit
	} else {
		$AzSubObj = $AzContext | Out-String
		Write-Output "Sets the Azure subscription. Result: `n$AzSubObj"
		$LogMessage = @{ hostpoolName_s = $HostpoolName; logmessage_s = "Sets the Azure subscription. Result: `n$AzSubObj" }
		Add-LogEntry -LogMessageObj $LogMessage -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId -LogAnalyticsPrimaryKey $LogAnalyticsPrimaryKey -logType "WVDTenantScale_CL" -TimeDifferenceInHours $TimeDifference
    }
#>
# Without Workspace
#else {
if ((!$LogAnalyticsWorkspaceId) -and (!$LogAnalyticsPrimaryKey)) {

	#Collect the credentials from Azure Automation Account Assets
	$Connection = Get-AutomationConnection -Name $ConnectionAssetName

	#Authenticating to Azure
	Clear-AzContext -Force
	$AZAuthentication = Connect-AzAccount -ApplicationId $Connection.ApplicationId -TenantId $AADTenantId -CertificateThumbprint $Connection.CertificateThumbprint -ServicePrincipal
	if ($null -eq $AZAuthentication) {
		Write-Output "Failed to authenticate Azure: $($_.exception.message)"
		exit
	}
	else {
		$AzObj = $AZAuthentication | Out-String
		Write-Output "Authenticating as service principal for Azure. Result: `n$AzObj"
	}
	#Set the Azure context with Subscription
	$AzContext = Set-AzContext -SubscriptionId $SubscriptionID
	if ($null -eq $AzContext) {
		Write-Error "Please provide a valid subscription"
		exit
	} else {
		$AzSubObj = $AzContext | Out-String
		Write-Output "Sets the Azure subscription. Result: `n$AzSubObj"
	}

	<#
	.Description
	Helper functions
	#>
	# Function to chceck and update the loadbalancer type is BreadthFirst
	function UpdateLoadBalancerTypeInPeakandOffPeakwithBredthFirst {
		param(
			[string]$HostpoolLoadbalancerType,
			[string]$ResourceGroupName,
			[string]$HostpoolName,
			[int]$MaxSessionLimitValue
		)
		if ($HostpoolLoadbalancerType -ne "BreadthFirst") {
			Write-Output "Changing hostpool load balancer type:'BreadthFirst' Current Date Time is: $CurrentDateTime"
			$EditLoadBalancerType = Update-AzWvdHostPool -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -LoadBalancerType BreadthFirst -MaxSessionLimit $MaxSessionLimitValue
			if ($EditLoadBalancerType.LoadBalancerType -eq 'BreadthFirst') {
				Write-Output "Hostpool load balancer type in peak hours is 'BreadthFirst Load Balancing'"
			}
		}

	}

	#Function to Check if the session host is allowing new connections
	function Check-ForAllowNewConnections
	{
		param(
			[string]$HostpoolName,
			[string]$ResourceGroupName,
			[string]$Name
		)

		# Check if the session host is allowing new connections
		$StateOftheSessionHost = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
		if (!($StateOftheSessionHost.AllowNewSession)) {
            Update-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name -AllowNewSession
            Write-Output "Updated $Name to allow new connections"
		}

	}
	# Start the Session Host 
	function Start-SessionHost
	{
		param(
			[string]$VMName
		)
		try {
			Get-AzVM | Where-Object { $_.Name -eq $VMName } | Start-AzVM -AsJob | Out-Null
		}
		catch {
			Write-Error "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)"
			exit
		}

	}
	# Stop the Session Host
	function Stop-SessionHost
	{
		param(
			[string]$VMName
		)
		try {
			Get-AzVM | Where-Object { $_.Name -eq $VMName } | Stop-AzVM -Force -AsJob | Out-Null
		}
		catch {
			Write-Error "Failed to stop Azure VM: $($VMName) with error: $($_.exception.message)"
			exit
		}
	}
	# Check if the Session host is available
	function Check-IfSessionHostIsAvailable
	{
		param(
			[string]$HostpoolName,
			[string]$Name,
			[string]$ResourceGroupName
		)
		$IsHostAvailable = $false
		while (!$IsHostAvailable) {
			$SessionHostStatus = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
			if ($SessionHostStatus.Status -eq "Available" -or $SessionHostStatus.Status -eq 'NeedsAssistance') {
				$IsHostAvailable = $true
			}
		}
		return $IsHostAvailable
	}

	#Converting date time from UTC to Local
	$CurrentDateTime = Convert-UTCtoLocalTime -TimeDifferenceInHours $TimeDifference

	$BeginPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
	$EndPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)

	#check the calculated end time is later than begin time in case of time zone
	if ($EndPeakDateTime -lt $BeginPeakDateTime) {
		$EndPeakDateTime = $EndPeakDateTime.AddDays(1)
	}

	#Checking givne host pool name exists in Tenant
	$HostpoolInfo = Get-AzWvdHostPool -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName
	if ($null -eq $HostpoolInfo) {
		Write-Output "Hostpoolname '$HostpoolName' does not exist. Ensure that you have entered the correct values."
		exit
	}

	# Setting up appropriate load balacing type based on PeakLoadBalancingType in Peak hours
	$HostpoolLoadbalancerType = $HostpoolInfo.LoadBalancerType
	[int]$MaxSessionLimitValue = $HostpoolInfo.MaxSessionLimit
	if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		UpdateLoadBalancerTypeInPeakandOffPeakwithBredthFirst -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -MaxSessionLimitValue $MaxSessionLimitValue -HostpoolLoadbalancerType $HostpoolLoadbalancerType
	}
	else {
		UpdateLoadBalancerTypeInPeakandOffPeakwithBredthFirst -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -MaxSessionLimitValue $MaxSessionLimitValue -HostpoolLoadbalancerType $HostpoolLoadbalancerType
	}
	Write-Output "Starting WVD tenant hosts scale optimization: Current Date Time is: $CurrentDateTime"
	# Check the after changing hostpool loadbalancer type
	$HostpoolInfo = Get-AzWvdHostPool -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName

	# Check if the hostpool have session hosts
	$ListOfSessionHosts = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Sort-Object Name
	if ($null -eq $ListOfSessionHosts) {
		Write-Output "Session hosts does not exist in the Hostpool of '$HostpoolName'. Ensure that hostpool have hosts or not?."
		exit
	}



	# Check if it is during the peak or off-peak time
	if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime)
	{
		Write-Output "It is in peak hours now"
		Write-Output "Starting session hosts as needed based on current workloads."

		# Peak hours check and remove the MinimumnoofRDSH value dynamically stored in automation variable 												   
		$AutomationAccount = Get-AzAutomationAccount -ErrorAction Stop | Where-Object { $_.AutomationAccountName -eq $AutomationAccountName }
		$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
		if ($OffPeakUsageMinimumNoOfRDSH) {
			Remove-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName
		}
		# Check the number of running session hosts
		[int]$NumberOfRunningHost = 0
		# Total of running cores
		[int]$TotalRunningCores = 0
		# Total capacity of sessions of running VMs
		$AvailableSessionCapacity = 0
		#Initialize variable for to skip the session host which is in maintenance.
		$SkipSessionhosts = 0
		$SkipSessionhosts = @()

		$HostPoolUserSessions = Get-AzWvdUserSession -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName

		foreach ($SessionHost in $ListOfSessionHosts) {

			$Name = $SessionHost.Name.Split("/")[1]| Out-String
			$VMName = $SessionHost.Name.Split(".")[0].Split("/")[1]
			# Check if VM is in maintenance
			$RoleInstance = Get-AzVM -Status -Name $VMName
			if ($RoleInstance.Tags.Keys -contains $MaintenanceTagName) {
				Write-Output "Session host is in maintenance: $VMName, so script will skip this VM"
				$SkipSessionhosts += $SessionHost
				continue
			}
			#$AllSessionHosts = Compare-Object $ListOfSessionHosts $SkipSessionhosts | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject }
			$AllSessionHosts = $ListOfSessionHosts | Where-Object { $SkipSessionhosts -notcontains $_ }

			Write-Output "Checking session host: $($SessionHost.Name | Out-String)  of sessions: $($SessionHost.Session) and status: $($SessionHost.Status)"
			if ($Name.ToLower().Contains($RoleInstance.Name.ToLower())) {
				# Check if the Azure vm is running       
				if ($RoleInstance.PowerState -eq "VM running") {
					[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
					# Calculate available capacity of sessions						
					$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
					$AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
					[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
				}
			}
		}
		Write-Output "Current number of running hosts:$NumberOfRunningHost"
		if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
			Write-Output "Current number of running session hosts is less than minimum requirements, start session host ..."
			# Start VM to meet the minimum requirement            
			foreach ($SessionHost in $AllSessionHosts) {
				# Check whether the number of running VMs meets the minimum or not
				if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
                    $Name = $SessionHost.Name.Split("/")[1]| Out-String
					$VMName = $SessionHost.Name.Split(".")[0].Split("/")[1]
					$RoleInstance = Get-AzVM -Status -Name $VMName
					if ($Name.ToLower().Contains($RoleInstance.Name.ToLower())) {
						# Check if the Azure VM is running and if the session host is healthy
						$SessionHostInfo = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
						if ($RoleInstance.PowerState -ne "VM running" -and $SessionHostInfo.UpdateState -eq "Succeeded") {
							# Check if the session host is allowing new connections
							Check-ForAllowNewConnections -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
							# Start the Az VM
							Write-Output "Starting Azure VM: $VMName and waiting for it to complete ..."
							Start-SessionHost -VMName $VMName

							# Wait for the VM to Start
							$IsVMStarted = $false
                            Write-Output "Checking PowerState on $($RoleInstance.Name) every 30 seconds to ensure it is started before moving on...  "
							while (!$IsVMStarted) {
								$RoleInstance = Get-AzVM -Status -Name $VMName
                                Write-Output "Last PowerState on $($RoleInstance.Name) was $($RoleInstance.PowerState). Waiting 30 seconds at $(get-date -Format s)"
                                start-sleep -Seconds 30
								if ($RoleInstance.PowerState -eq "VM running") {
									$IsVMStarted = $true
									Write-Output "Azure VM has been Started: $($RoleInstance.Name) ..."
								}
							}
							# Wait for the VM to start
							$SessionHostIsAvailable = Check-IfSessionHostIsAvailable -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
							if ($SessionHostIsAvailable) {
								Write-Output "'$SessionHost' session host status is 'Available'"
							}
							else {
								Write-Output "'$SessionHost' session host does not configured properly with deployagent or does not started properly"
							}
							# Calculate available capacity of sessions
							$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
							$AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
							[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
							[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
							if ($NumberOfRunningHost -ge $MinimumNumberOfRDSH) {
								break;
							}
						}
					}
				}
			}
		}
		else {
			#check if the available capacity meets the number of sessions or not
			Write-Output "Current total number of user sessions: $(($HostPoolUserSessions).Count)"
			Write-Output "Current available session capacity is: $AvailableSessionCapacity"
			if ($HostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
				Write-Output "Current available session capacity is less than demanded user sessions, starting session host"
				# Running out of capacity, we need to start more VMs if there are any 
				foreach ($SessionHost in $AllSessionHosts) {
					if ($HostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
                        $Name = $SessionHost.Name.Split("/")[1] 
						$VMName = $SessionHost.Name.Split(".")[0].Split("/")[1]
						$RoleInstance = Get-AzVM -Status -Name $VMName
                        Write-Output "Variable logging event. Name: $Name, VMName: $VMName, RoleInstance: $RoleInstance"
						if ($Name.ToLower().Contains($RoleInstance.Name.ToLower())) {
                            # Check if the Azure VM is running and if the session host is healthy
                            Write-Output "Check if the Azure VM is running and if the session host is healthy"
                            $SessionHostInfo = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
                            Write-Output "SessionHost Update State is ready for new changes"
							if ($RoleInstance.PowerState -ne "VM running" -and $SessionHostInfo.UpdateState -eq "Succeeded") {
								# Validating session host is allowing new connections
								Check-ForAllowNewConnections -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
								# Start the Az VM
								Write-Output "Starting Azure VM: $VMName and waiting for it to complete ..."
								Start-SessionHost -VMName $VMName
								# Wait for the VM to Start
								$IsVMStarted = $false
                                Write-Output "Checking PowerState on $($RoleInstance.Name) every 30 seconds to ensure it is started before moving on...  "
								while (!$IsVMStarted) {
									$RoleInstance = Get-AzVM -Status -Name $VMName
                                    Write-Output "Last PowerState on $($RoleInstance.Name) was $($RoleInstance.PowerState). Waiting 30 seconds at $(get-date -Format s)"
                                    start-sleep -Seconds 30
									if ($RoleInstance.PowerState -eq "VM running") {
										$IsVMStarted = $true
										Write-Output "Azure VM has been Started: $($RoleInstance.Name) ..."
									}
								}
								$SessionHostIsAvailable = Check-IfSessionHostIsAvailable -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
								if ($SessionHostIsAvailable) {
									Write-Output "'$SessionHost' session host status is 'Available'"
								}
								else {
									Write-Output "'$SessionHost' session host does not configured properly with deployagent or does not started properly"
								}
								# Calculate available capacity of sessions
								$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
								$AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
								[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
								[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
								Write-Output "New available session capacity is: $AvailableSessionCapacity"
								if ($AvailableSessionCapacity -gt $HostPoolUserSessions.Count) {
									break
								}
							}
							#Break # break out of the inner foreach loop once a match is found and checked
						}
					}
				}
			}
		}
	}
	else
	{
		Write-Output "It is Off-peak hours"
		Write-Output "Starting to scale down WVD session hosts ..."
		Write-Output "Processing hostpool $($HostpoolName)"
		# Check the number of running session hosts
		[int]$NumberOfRunningHost = 0
		# Total number of running cores
		[int]$TotalRunningCores = 0
		#Initialize variable for to skip the session host which is in maintenance.
		$SkipSessionhosts = 0
		$SkipSessionhosts = @()
		# Check if minimum number of rdsh vm's are running in off peak hours
		$CheckMinimumNumberOfRDShIsRunning = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName | Where-Object { $_.Status -eq "Available" -or $_.Status -eq 'NeedsAssistance' }
		$ListOfSessionHosts = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName
		if ($null -eq $CheckMinimumNumberOfRDShIsRunning) {
			foreach ($Name in $ListOfSessionHosts.Name) {
				if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
					$VMName = $SessionHost.Name.Split(".")[0].Split("/")[1]
					$RoleInstance = Get-AzVM -Status -Name $VMName
					# Check the session host is in maintenance
					if ($RoleInstance.Tags.Keys -contains $MaintenanceTagName) {
						continue
					}
					# Check if the session host is allowing new connections
					Check-ForAllowNewConnections -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name

					Start-SessionHost -VMName $VMName
					# Wait for the VM to Start
					$IsVMStarted = $false
                    Write-Output "Checking PowerState on $($RoleInstance.Name) every 30 seconds to ensure it is started before moving on...  "
					while (!$IsVMStarted) {
						$RoleInstance = Get-AzVM -Status -Name $VMName
                         Write-Output "Last PowerState on $($RoleInstance.Name) was $($RoleInstance.PowerState). Waiting 30 seconds at $(get-date -Format s)"
						 start-sleep -Seconds 30
						if ($RoleInstance.PowerState -eq "VM running") {
							$IsVMStarted = $true
						}
					}
					# Check if session host is available
					$SessionHostIsAvailable = Check-IfSessionHostIsAvailable -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
					if ($SessionHostIsAvailable) {
						Write-Output "'$Name' session host status is 'Available'"
					}
					else {
						Write-Output "'$SessionHost' session host does not configured properly with deployagent or does not started properly"
					}
					[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
					if ($NumberOfRunningHost -ge $MinimumNumberOfRDSH) {
						break;
					}


				}
			}
		}

		$ListOfSessionHosts = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName | Sort-Object Sessions
		$NumberOfRunningHost = 0
		foreach ($SessionHost in $ListOfSessionHosts) {
			$Name = $SessionHost.Name.Split("/")[1] 
			$VMName = $SessionHost.Name.Split(".")[0].Split("/")[1]
			$RoleInstance = Get-AzVM -Status -Name $VMName
			# Check the session host is in maintenance
			if ($RoleInstance.Tags.Keys -contains $MaintenanceTagName) {
				Write-Output "Session host is in maintenance: $VMName, so script will skip this VM"
				$SkipSessionhosts += $SessionHost
				continue
			}
			# Maintenance VMs skipped and stored into a variable
			$AllSessionHosts = $ListOfSessionHosts | Where-Object { $SkipSessionhosts -notcontains $_ }
			if ($Name.ToLower().Contains($RoleInstance.Name.ToLower())) {
				# Check if the Azure VM is running
				if ($RoleInstance.PowerState -eq "VM running") {
					Write-Output "Checking session host: $($SessionHost.Name | Out-String)  of sessions: $($SessionHost.Session) and status: $($SessionHost.Status)"
					[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
					# Calculate available capacity of sessions  
					$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
					[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
				}
			}
		}
		# Defined minimum no of rdsh value from webhook data
		[int]$DefinedMinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH
		## Check and Collecting dynamically stored MinimumNoOfRDSH value																 
		$AutomationAccount = Get-AzAutomationAccount -ErrorAction Stop | Where-Object { $_.AutomationAccountName -eq $AutomationAccountName }
		$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
		if ($OffPeakUsageMinimumNoOfRDSH) {
			[int]$MinimumNumberOfRDSH = $OffPeakUsageMinimumNoOfRDSH.Value
			if ($MinimumNumberOfRDSH -lt $DefinedMinimumNumberOfRDSH) {
				Write-Output "Don't enter the value of '$HostpoolName-OffPeakUsage-MinimumNoOfRDSH' manually, which is dynamically stored value by script. You have entered manually, so script will stop now."
				exit
			}
		}

		# Breadth first session hosts shutdown in off peak hours
		if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {
			Write-Output "Running section 'Breadth first session hosts shutdown in off peak hours'  "
			foreach ($SessionHost in $AllSessionHosts) {
                #Check the status of the session host
                $Name = $SessionHost.Name.Split("/")[1] 
                $VMName = $SessionHost.Name.Split(".")[0].Split("/")[1]
                $RoleInstance = Get-AzVM -Status -Name $VMName
				Write-Output "Looping through potential hosts for shutdown during off-peak hours. Target session host is now $($RoleInstance.Name),  "
				Write-Output "Checking heartbeat status on $($RoleInstance.Name),  "
				if ($SessionHost.Status -ne "NoHeartbeat" -and $SessionHost.Status -ne "Unavailable") {
					Write-Output "$($RoleInstance.Name) reported a heartbeat. Evaluating this host for shutdown. "
					if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {
						Write-Output "Current number of running hosts is greater than minimum required during off-peak hours. CurrentHosts: $NumberOfRunningHost, MinHosts: $MinimumNumberOfRDSH.  "
						if ($SessionHost.Session -eq 0) {
							# Shutdown the Azure VM, which session host have 0 sessions
							Write-Output "No Sessions found for $VMName. Stopping Azure VM: $VMName and waiting for it to complete ... "
							Stop-SessionHost -VMName $VMName
						}
						else {
							# Check if LimitSecondsToForceLogOffUser equals to zero
                            if ($LimitSecondsToForceLogOffUser -eq 0) {
								continue
							}
                            
                            # Ensure the running Azure VM is set as drain mode
							try {
								$KeepDrianMode = Update-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name -AllowNewSession:$false -ErrorAction Stop
							}
							catch {
								Write-Output "Unable to set it to allow connections on session host: $Name with error: $($_.exception.message)"
								exit
							}
							
							# Notify user to log off session
							# Get the user sessions in the hostpool
							try {
								$HostPoolUserSessions = Get-AzWvdUserSession -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName | Where-Object { $_.Name -eq $Name }
							}
							catch {
								Write-Output "Failed to retrieve user sessions in hostpool: $($HostpoolName) with error: $($_.exception.message)"
								exit
							}
							$HostUserSessionCount = ($HostPoolUserSessions | Where-Object -FilterScript { $_.Name -eq $Name }).Count
							Write-Output "Counting the current sessions on the host $Name :$HostUserSessionCount"

							$ExistingSession = 0
							foreach ($session in $HostPoolUserSessions) {
								if ($session.Name -eq $Name -and $session.SessionState -eq "Active") {
									#if ($LimitSecondsToForceLogOffUser -ne 0) {
									# Send notification
									try {
										Send-AzWvdUserSessionMessage -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name -SessionId $session.SessionId -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will be logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt -ErrorAction Stop
									}
									catch {
										Write-Output "Failed to send message to user with error: $($_.exception.message)"
										exit
									}
									Write-Output "Script was sent a log off message to user: $($Session.AdUserName | Out-String)"
									#}
								}
								$ExistingSession = $ExistingSession + 1
							}
							# Wait for n seconds to log off user
							Start-Sleep -Seconds $LimitSecondsToForceLogOffUser

							#if ($LimitSecondsToForceLogOffUser -ne 0) {
							# Force users to log off
							Write-Output "Force users to log off ..."
							foreach ($Session in $HostPoolUserSessions) {
								if ($Session.Name -eq $Name) {
									#Log off user
									try {
										Disconnect-AzWvdUserSession -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Session.Name -SessionId $Session.SessionId -NoUserPrompt -ErrorAction Stop
										$ExistingSession = $ExistingSession - 1
									}
									catch {
										Write-Output "Failed to log off user with error: $($_.exception.message)"
										exit
									}
									Write-Output "Forcibly logged off the user: $($Session.AdUserName | Out-String)"
								}
							}
							#}
							# Check the session count before shutting down the VM
							if ($ExistingSession -eq 0) {
								# Shutdown the Azure VM
								Write-Output "Stopping Azure VM: $VMName and waiting for it to complete ..."
								Stop-SessionHost -VMName $VMName
							}
						}

						if ($LimitSecondsToForceLogOffUser -ne 0 -or $SessionHost.Session -eq 0) {
							#wait for the VM to stop
                            $IsVMStopped = $false
                            Write-Output "Checking PowerState on $($RoleInstance.Name) every 30 seconds to ensure it is deallocated before moving on...  "
							While ($IsVMStopped -eq $false) {
                                Write-Output "Last PowerState on $($RoleInstance.Name) was $($RoleInstance.PowerState). Waiting 30 seconds at $(get-date -Format s)"
								start-sleep -Seconds 30
								$RoleInstance = Get-AzVM -Status -Name $VMName
								if ($RoleInstance.PowerState -eq "VM deallocated") {
									$IsVMStopped = $true
									Write-Output "Azure VM has been stopped: $($RoleInstance.Name) ...  "
								}
							}
							# Check if the session host status is NoHeartbeat or Unavailable                          
							$IsSessionHostNoHeartbeat = $false
							while (!$IsSessionHostNoHeartbeat) {
                                Write-Output "Waiting for $($RoleInstance.Name) to stop reporting a heartbeat to WVD srevice. Waiting 30 seconds at $(get-date -Format s)"
								start-sleep -Seconds 30
                                $RoleInstance = Get-AzVM -Status -Name $VMName
								$SessionHostInfo = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
								if ($SessionHostInfo.UpdateState -eq "Succeeded" -and ($SessionHostInfo.Status -eq "Unavailable" -or $SessionHostInfo.Status -eq "NoHeartbeat")) {
									$IsSessionHostNoHeartbeat = $true
									Write-Output "$($RoleInstance.Name) heartbeart is now offline, moving on.  "
									# Ensure the Azure VMs that are off have allow new connections mode set to True
									if ($SessionHostInfo.AllowNewSession -eq $false) {
										Check-ForAllowNewConnections -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name;
										Write-Output "$($RoleInstance.Name) is no longer accepting new connections  "
									}
								}
							}
						}
						$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
						#decrement number of running session host
						if ($LimitSecondsToForceLogOffUser -ne 0 -or $SessionHost.Session -eq 0) {
							Write-Output "Removing $($RoleInstance.Name) from the running count,  "
							Write-Output "Pre-operation count -- Hosts: [int]$NumberOfRunningHost. Cores: [int]$TotalRunningCores." 
							[int]$NumberOfRunningHost = [int]$NumberOfRunningHost - 1
							[int]$TotalRunningCores = [int]$TotalRunningCores - $RoleSize.NumberOfCores
							Write-Output "Post-operation count -- Hosts: [int]$NumberOfRunningHost. Cores: [int]$TotalRunningCores." 
						}
					}
				}
			}
		}

		$AutomationAccount = Get-AzAutomationAccount -ErrorAction Stop | Where-Object { $_.AutomationAccountName -eq $AutomationAccountName }
		$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
		if ($OffPeakUsageMinimumNoOfRDSH) {
			[int]$MinimumNumberOfRDSH = $OffPeakUsageMinimumNoOfRDSH.Value
			$NoConnectionsofhost = 0
			if ($NumberOfRunningHost -le $MinimumNumberOfRDSH) {
				foreach ($SessionHost in $AllSessionHosts) {
					if (($SessionHost.Status -eq "Available" -or $SessionHost.Status -eq 'NeedsAssistance') -and $SessionHost.Session -eq 0) {
						$NoConnectionsofhost = $NoConnectionsofhost + 1
					}
				}
				$NoConnectionsofhost = $NoConnectionsofhost - $DefinedMinimumNumberOfRDSH
				if ($NoConnectionsofhost -gt $DefinedMinimumNumberOfRDSH) {
					[int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH - $NoConnectionsofhost
					Set-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Encrypted $false -Value $MinimumNumberOfRDSH
				}
			}
		}
		$HostpoolMaxSessionLimit = $HostpoolInfo.MaxSessionLimit
		$HostpoolSessionCount = (Get-AzWvdUserSession -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName).Count
		if ($HostpoolSessionCount -ne 0)
		{
			# Calculate the how many sessions will allow in minimum number of RDSH VMs in off peak hours and calculate TotalAllowSessions Scale Factor
			$TotalAllowSessionsInOffPeak = [int]$MinimumNumberOfRDSH * $HostpoolMaxSessionLimit
			$SessionsScaleFactor = $TotalAllowSessionsInOffPeak * 0.90
			$ScaleFactor = [math]::Floor($SessionsScaleFactor)

			if ($HostpoolSessionCount -ge $ScaleFactor) {
				$ListOfSessionHosts = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName | Where-Object { $_.Status -eq "NoHeartbeat" -or $_.Status -eq "Unavailable"}
				$AllSessionHosts = $ListOfSessionHosts | Where-Object { $SkipSessionhosts -notcontains $_ }
				foreach ($SessionHost in $AllSessionHosts) {
					# Check the session host status and if the session host is healthy before starting the host
					if ($SessionHost.UpdateState -eq "Succeeded") {
						Write-Output "Existing sessionhost sessions value reached near by hostpool maximumsession limit need to start the session host"
						$Name = $SessionHost.Name.Split("/")[1] 
						$VMName = $SessionHost.Name.Split(".")[0].Split("/")[1]
						# Validating session host is allowing new connections
						Check-ForAllowNewConnections -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
						# Start the Az VM
						Write-Output "Starting Azure VM: $VMName and waiting for it to complete ..."
						Start-SessionHost -VMName $VMName
						#Wait for the VM to start
						$IsVMStarted = $false
                        Write-Output "Checking PowerState on $($RoleInstance.Name) every 30 seconds to ensure it is started before moving on...  "
						while (!$IsVMStarted) {
							    $RoleInstance = Get-AzVM -Status -Name $VMName
                                Write-Output "Last PowerState on $($RoleInstance.Name) was $($RoleInstance.PowerState). Waiting 30 seconds at $(get-date -Format s)"
                                start-sleep -Seconds 30
							if ($RoleInstance.PowerState -eq "VM running") {
								$IsVMStarted = $true
								Write-Output "Azure VM has been started: $($RoleInstance.Name) ..."
							}
						}
						# Wait for the sessionhost is available
						$SessionHostIsAvailable = Check-IfSessionHostIsAvailable -HostPoolName $HostpoolName -ResourceGroupName $ResourceGroupName -Name $Name
						if ($SessionHostIsAvailable) {
							Write-Output "'$($SessionHost.Name | Out-String)' session host status is 'Available'"
						}
						else {
							Write-Output "'$($SessionHost.Name | Out-String)' session host does not configured properly with deployagent or does not started properly"
						}
						# Increment the number of running session host
						[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
						# Increment the number of minimumnumberofrdsh
						[int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH + 1
						$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
						if ($null -eq $OffPeakUsageMinimumNoOfRDSH) {
							New-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Encrypted $false -Value $MinimumNumberOfRDSH -Description "Dynamically generated minimumnumber of RDSH value"
						}
						else {
							Set-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Encrypted $false -Value $MinimumNumberOfRDSH
						}
						# Calculate available capacity of sessions
						$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
						$AvailableSessionCapacity = $TotalAllowSessions + $HostpoolInfo.MaxSessionLimit
						[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
						Write-Output "New available session capacity is: $AvailableSessionCapacity"
						break
					}
				}
			}

		}
	}
	Write-Output "HostpoolName: $HostpoolName, TotalRunningCores: $TotalRunningCores NumberOfRunningHosts: $NumberOfRunningHost"
    if (!$testrun){
	Write-Output "End WVD tenant scale optimization. Posting a message to the callback url."
    Invoke-WebRequest -UseBasicParsing -Method POST -Uri $CallbackUrl
    } else {
        Write-Output "End WVD tenant scale optimization."
    }
}
