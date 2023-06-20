<#
This PS script will create policy defination under a subscription using policy defination json template. This template file contains
policy metadata, rules and parameters.
If subscription id and management group not provided current subscription will be used
If management group is provided it will be used
Based on a blog article from Tao Yang 
https://blog.tyang.org/2019/05/19/deploying-azure-policy-definitions-via-azure-devops-part-1/
#>
param(
  [string] [Parameter(Mandatory=$true)] $TemplateFile,
  [string] $SubscriptionId,
  [string] $ManagementGroup

)

Function ConnectToAzure
{
	if ($context -eq $null){
		write-host "No signed context found. Try connecting Azure account"
		 $null = Connect-AzAccount
		 $context = Get-AzContext -ErrorAction Stop
	}
    $Script:currentTenantId = $context.Tenant.Id
    $Script:currentSubId = $context.Subscription.Id
	$currentSubId;
	
}

Function DeployPolicyDefinition
{
    Param (
      [object]$Definition,
      [String]$subscriptionId
    )
    #Extract from policy definition
    $policyName = $Definition.name
	  $policyMode = $Definition.properties.mode
    $policyDisplayName = $Definition.properties.displayName
    $policyDescription = $Definition.properties.description
    $policyParameters = $Definition.properties.parameters | convertTo-Json
    $PolicyRule = $Definition.properties.policyRule | convertTo-Json -Depth 15
    $policyMetaData = $Definition.properties.metadata | convertTo-Json
    $deployParams = @{
      Name = $policyName
      DisplayName = $policyDisplayName
      Description = $policyDescription
      Parameter = $policyParameters
      Policy = $PolicyRule
      Metadata = $policyMetaData
    }

	if($policyMode -ne $null)
	{
		$deployParams.Add('Mode', $policyMode)
	}
	else
	{
		write-host "Policy mode is not set. Hence policy will be created without passing mode"
	}

    if ($ManagementGroup -eq '' )
    {
	  write-host "Creating policy defination under given Subscription:$subscriptionId" 
      $deployParams.Add('SubscriptionId', $subscriptionId)
    }
    else 
	{
	  write-host "Creating policy initiative under given Management Group: $ManagementGroup" 
      $deployParams.Add('ManagementGroupName', $ManagementGroup)
    }

    $deployResult = New-AzPolicyDefinition @deployParams
    return $deployResult
}

#Sign in to Azure
$context = Get-AzContext -ErrorAction SilentlyContinue
ConnectToAzure

#Read Template
Write-host "Reading '$TemplateFile'..."
$objDef = Get-Content -path $TemplateFile | Convertfrom-Json

#If no subscription is given use current subscription
if ($SubscriptionId -eq '' )
	{
		$SubscriptionId = $context.Subscription.Id;
		write-host "No subscription is passed in parameter. So default connected SubscriptionId: $SubscriptionId is used."
	}
else
{
	write-host "SubscriptionId passed in parameter: $SubscriptionId"
}

$deployResult = DeployPolicyDefinition $objDef $SubscriptionId
write-host "$deployResult"
return $deployResult