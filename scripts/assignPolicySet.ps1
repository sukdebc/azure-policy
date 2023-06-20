
<#
This script will assign a policy as per the policy assignment Json file which defines assignment name, scope, policy defination id and parameters
$TemplateFile: policy assignment Json file
$SubscriptionId: subscription id
#>
param(
	[string][Parameter(Mandatory=$true)] $TemplateFile,
	[string] $SubscriptionId

)

Import-Module -Name Az -RequiredVersion 3.5.0 

Function ProcessAzureSignIn
{
	if ($null -eq $context){
		 $null = Connect-AzAccount
		 $context = Get-AzContext -ErrorAction Stop
	}
    $currentSubId = $context.Subscription.Id
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
    $policySetDefinitionId = $objAssignment.properties.policySetDefinitionId
	$assignmentScope = $objAssignment.properties.scope
    $assignmentParameters = $objAssignment.properties.parameters | convertTo-Json
	$assignmentIdentity = $objAssignment.properties.AssignIdentity
	$assignmentLocation = $objAssignment.properties.Location
	$roleDefinitionIds = $objAssignment.properties.RoleDefinitionIds
	$RoleAssignmentRetryCount = $objAssignment.properties.RoleAssignmentRetryCount
	$nonComplianceMessages = $objAssignment.properties.nonComplianceMessages
	$enforcementMode = "Default"
	# Check if enforcementMode is present else set a default value
	if($objAssignment.properties.PSobject.Properties.name -match "enforcementMode")
	{
		$enforcementMode = $objAssignment.properties.enforcementMode
		if($enforcementMode -notin "DoNotEnforce", "Default")
		{
		    Write-Warning "EnforcementMode is setup with value:$enforcementMode which is not correct. Allowed values are: DoNotEnforce, Default. Hence value is defaulted to Default "
			$EnforcementMode = "Default"
		}
	}
	 #Get policy definition
	$Policy = Get-AzPolicySetDefinition -Id $policySetDefinitionId

    $deployParams = @{
      Name = $assignmentName
      DisplayName = $assignmentDisplayName
      Description = $assignmentDescription
      PolicyParameter = $assignmentParameters
      PolicySetDefinition = $Policy
	  Scope = $assignmentScope
	  EnforcementMode = $enforcementMode
	  NonComplianceMessage = $nonComplianceMessages
    }
	
	#Check for AssignIdentity. 'AssignIdentity' pass true only for the modify and deployeIfNotExists. Other policy don't pass the Parameter
	if($assignmentIdentity -eq "true"){
		$assignment = New-AzPolicyAssignment @deployParams -AssignIdentity -Location $assignmentLocation
	}
	else{
		$assignment = New-AzPolicyAssignment @deployParams  
	}

	# Assign role to managed identity
	if (($assignmentIdentity -eq "true") -and ($roleDefinitionIds.Count -gt 0))
	{
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
$DefFileContent = Get-Content -path $TemplateFile -Raw -ErrorAction Stop 

#replace policy definition resource Ids
 Write-host "Replacing subscription id. in json file"
$DefFileContent = $DefFileContent.Replace("{subscriptionId}", $SubscriptionId)
#Parse JOSN
$objDef = Convertfrom-Json -InputObject $DefFileContent -ErrorAction Stop 

$deployResult = AssignPolicy $objDef
write-host $deployResult


