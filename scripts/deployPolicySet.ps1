<# 
This PS script will create policy initiative under a subscription or management group using json template. This template file contains
policy definations, metadata and parameters.
If subscription id and management group not provided current subscription will be used
If management group is provided it will be used
Note: This script supports deploying initiative definitions that contains custom policy definitions without hardcoding definition Ids
Syntax: .\deploy-policyInitiative.ps1 -TemplateFile c:\temp\azurepolicyset.json -PolicyLocations @{policyLocation1 = '/providers/Microsoft.Management/managementgroups/MGName'} -ManagementGroupName MGName
Based on a blog article from Tao Yang 
https://blog.tyang.org/2019/05/19/deploying-azure-policy-definitions-via-azure-devops-part-1/
#>
param(
  [string] [Parameter(Mandatory=$true)] $TemplateFile,
  [string] $SubscriptionId,
  [string] $ManagementGroup,
  [hashtable]$PolicyLocations
)

#Import-Module -Name Az -RequiredVersion 3.5.0 
#Import-Module Az.Resources

Function ConnectToAzure
{
	if ($context -eq $null){
		write-host "No signed context found. Try connecting Azure account"
		 $null = Connect-AzAccount
		 $context = Get-AzContext -ErrorAction Stop
	}
    $Script:currentTenantId = $context.Tenant.Id
    $Script:currentSubId = $context.Subscription.Id
	Write-host "Connected default subscription:$currentSubId"
	
}

Function DeployPolicyInitiative
{
    Param (
      [object]$PolInitiative,
      [String]$subscriptionId
    )
    #Extract from policy initiative
    $policyName = $PolInitiative.name
    $policyDisplayName = $PolInitiative.properties.displayName
    $policyDescription = $PolInitiative.properties.description
    $policyParameters = convertTo-Json -InputObject $PolInitiative.properties.parameters -Depth 15
    $PolicyDefinitions = convertTo-Json -InputObject $PolInitiative.properties.policyDefinitions -Depth 15 
    $policyMetaData = convertTo-Json -InputObject $PolInitiative.properties.metadata -Depth 15
    $deployParams = @{
      Name = $policyName
      DisplayName = $policyDisplayName
      Description = $policyDescription
      Parameter = $policyParameters
      PolicyDefinition = $PolicyDefinitions
      Metadata = $policyMetaData
    }

    if ($ManagementGroup -eq '' )
    {
      write-host "Creating policy initiative under given Subscription:$subscriptionId" 
      $deployParams.Add('SubscriptionId', $subscriptionId)
    }
    else {
      write-host "Creating policy initiative under given Management Group: $ManagementGroup" 
      $deployParams.Add('ManagementGroupName', $ManagementGroup)
    }
    write-host "Creating policy initiative." 
    $result = New-AzPolicySetDefinition @deployParams
    write-host $result
    return $result
}

#Sign in to Azure
$context = Get-AzContext -ErrorAction SilentlyContinue
ConnectToAzure

#Read initiative definition
Write-host "Reading '$TemplateFile'..."
$FileContent = Get-Content -path $TemplateFile -Raw -ErrorAction Stop 

#replace policy definition resource Ids
If ($PSBoundParameters.ContainsKey('PolicyLocations'))
{
    Write-Host "Replacing policy locations."
    Foreach ($key in $PolicyLocations.Keys)
    {
        $FileContent = $FileContent.Replace("{$key}", $PolicyLocations.$key)
    }
}
#Read Template
$objInitiative = Convertfrom-Json -InputObject $FileContent -ErrorAction Stop 

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

$result = DeployPolicyInitiative $objInitiative $SubscriptionId
Write-Host "$result"
return $result