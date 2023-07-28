
<#
This script will assign a policy as per the policy assignment Json file which defines assignment name, scope, policy defination id and parameters
It also performs role assignment. Role is prefered to be defined in assignment json. If not role will be taken from policy def
$TemplateFile: policy assignment Json file
$SubscriptionId: subscription id
#>
param(
	[string][Parameter(Mandatory=$true)] $TemplateFile,
	[string] $SubscriptionId

)

Function ProcessAzureSignIn
{
	if ($context -eq $null){
		 $null = Connect-AzAccount
		 $context = Get-AzContext -ErrorAction Stop
	}
    $currentTenantId = $context.Tenant.Id
    $currentSubId = $context.Subscription.Id
    $currentSubName = $context.Subscription.Name
	$currentSubId
}

Function AssignRole($Scope, $ObjectId, $RoleDefinitionId, $retryCount) {
	$totalRetries = $retryCount
    While ($True) {
        Try {
			$ErrorActionPreference = "Stop";
			New-AzRoleAssignment -Scope $Scope -ObjectId $ObjectId -RoleDefinitionId $RoleDefinitionId
            Return
        }
        Catch {
            # The principal could not be found. Maybe it was just created.
            If ($retryCount -eq 0) {
                Write-Error "An error occurred: $($_.Exception)`n$($_.ScriptStackTrace)"
                throw "The principal '$objectId' cannot be granted '$RoleDefinitionId' role on the scope '$Scope'. Please make sure the principal exists and try again later."
            }
            $retryCount--
            Write-Warning "  The principal '$objectId' cannot be granted '$RoleDefinitionId' role on the scope '$Scope'. Trying again (attempt $($totalRetries - $retryCount)/$totalRetries)"
            Start-Sleep -s 10
		}
		finally{
			$ErrorActionPreference = "Continue";
		}
    }
}

Function AssignPolicy
{
    Param (
      [object]$objAssignment
    )

	#Extract from policy definition
    $assignmentName = $objAssignment.name
	$assignmentDisplayName = $objAssignment.properties.displayName
	$assignmentDescription = $objAssignment.properties.description
    $policyDefinitionId = $objAssignment.properties.policyDefinitionId
	$assignmentScope = $objAssignment.properties.scope
    $assignmentParameters = $objAssignment.properties.parameters | convertTo-Json
	$assignmentIdentity = $objAssignment.properties.AssignIdentity
	$assignmentLocation = $objAssignment.properties.Location
	$nonComplianceMessages = $objAssignment.properties.nonComplianceMessages
	$enforcementMode = "Default"
	# Check if enforcementMode is present else set a default value
	if($objAssignment.properties.PSobject.Properties.name -match "enforcementMode")
	{
		$enforcementMode = $objAssignment.properties.enforcementMode
		if($enforcementMode -notin "DoNotEnforce", "Default")
		{
		    Write-Warning "EnforcementMode is setup with value: $enforcementMode which is not correct. Allowed values are: DoNotEnforce, Default. Hence value is defaulted to Default "
			$enforcementMode = "Default"
		}
	}
	 #Get policy definition
	$Policy = Get-AzPolicyDefinition -Id $policyDefinitionId

    $deployParams = @{
      Name = $assignmentName
      DisplayName = $assignmentDisplayName
      Description = $assignmentDescription
      PolicyParameter = $assignmentParameters
      PolicyDefinition = $Policy
	  Scope = $assignmentScope	
	  EnforcementMode = $enforcementMode
	  NonComplianceMessage = $nonComplianceMessages

    }
	
	#Check for AssignIdentity. 'AssignIdentity' pass true only for the modify and deployeIfNotExists. Other policy don't pass the Parameter
	if($assignmentIdentity -eq "true"){
		$assignment = New-AzPolicyAssignment @deployParams -IdentityType "SystemAssigned" -Location $assignmentLocation
	}
	else{
		$assignment = New-AzPolicyAssignment @deployParams  
	}
	
	#Get Role Defination ID if present in assignment json
	if($objAssignment.properties.PSobject.Properties.name -match "RoleDefinitionIds")
	{
		write-host "Getting role id from JSON"
		$roleDefinitionIds = $objAssignment.properties.RoleDefinitionIds
	}


	# Use the $policyDef to get the roleDefinitionIds array in case roles are not defined in assignment json
	if($roleDefinitionIds.Count -le 0)
	{
		write-host "No role id defined in assignment json. Getting role id from Policy Def"
		$roleDefinitionIds = $Policy.Properties.policyRule.then.details.roleDefinitionIds
	}
	
	# Assign role to managed identity
	if (($assignmentIdentity -eq "abc") -and ($roleDefinitionIds.Count -gt 0))
	{
		write-host "Starting role assignment"
		# Check if retry count is present else set a default value
		if($objAssignment.properties.PSobject.Properties.name -match "RoleAssignmentRetryCount")
		{
			$RoleAssignmentRetryCount = $objAssignment.properties.RoleAssignmentRetryCount
		}
		else {
			$RoleAssignmentRetryCount = 10
		}
		$roleDefinitionIds | ForEach-Object {
			$roleDefId = $_.Split("/") | Select-Object -Last 1
			AssignRole -Scope $assignmentScope -ObjectId $assignment.Identity.PrincipalId -RoleDefinitionId $roleDefId -retryCount $RoleAssignmentRetryCount 
		}
	}
	else
	{
		Write-Warning "Either assignmentIdentity is not set or roleDefinitionIds count is zero. Hence No Role Assignment is performed. Ignore if role assignment is not needed."
	}
	
    $assignment
}

#Sign in to Azure
$context = Get-AzContext -ErrorAction SilentlyContinue
ProcessAzureSignIn

#If no subscription is given use current subscription
if ($SubscriptionId -eq '' )
	{
		$SubscriptionId = $context.Subscription.Id;
	}

#Read assignment template
Write-host "Processing '$TemplateFile'..."
$DefFileContent = Get-Content -path $TemplateFile -Raw

#replace policy definition resource Ids
 Write-host "Replacing subscription id. in json file"
$DefFileContent = $DefFileContent.Replace("{subscriptionId}", $SubscriptionId)
#Parse JOSN
$objDef = Convertfrom-Json -InputObject $DefFileContent

$deployResult = AssignPolicy $objDef
write-host $deployResult


