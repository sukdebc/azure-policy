$RepoRootPath = "/Users/sukdeb.chakraborty/repo/azure-policy/"
$PolicyFolder = "Generic/Naming"
$SubscriptionId = "<Enter>"
$ManagementGroup = ""
$PolicyLocations = "/subscriptions/$SubscriptionId"
#Policy Location for Management Group
#$PolicyLocations = "/providers/Microsoft.Management/managementGroups/$ManagementGroup"

$definitionFile = (Get-ChildItem -Path $RepoRootPath\$PolicyFolder -File -Filter 'pol-*.json' -Recurse  -Exclude *lvm*,*wvm*).FullName
#[io.path]::GetFileNameWithoutExtension($RepoRootPath)

$count = 0
Foreach ($file in $definitionFile)
{
    If ($file -notContains $excludedPathFilter){
    
        $count = $count + 1
        #To Create Policy in subscription level
        &"$RepoRootPath/scripts/deployPolicy.ps1" -TemplateFile $file -SubscriptionId $SubscriptionId
        Write-host "Processing '$file'..."
        Write-host ""
    }
}

Write-Host "###############No. of Policy Created: $count ##################"

#Initiative def and assignment for naming
#& "$RepoRootPath\deployPolicySet.ps1" -TemplateFile "$RepoRootPath\$PolicyFolder\Monitoring-Initiative\platform-ini-all-deploy diagnostic settings-arm.json" -PolicyLocations @{policyLocation1 = $PolicyLocations} -SubscriptionId $SubscriptionId
#& "$RepoRootPath\assignPolicySet.ps1" -TemplateFile "$RepoRootPath\Naming\Naming-initiative\policySetAssignment-nonprod.json" -SubscriptionId $SubscriptionId