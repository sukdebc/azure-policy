# Azure Policy
Azure Policy is a service provided by Microsoft Azure that allows you to enforce and govern your organization's compliance and security requirements across your Azure resources. It helps you establish and maintain consistent guidelines and best practices for resource configurations and deployments within your Azure environment. 

By leveraging Azure Policy, organizations can ensure that their Azure resources align with security and compliance standards, streamline governance processes, and maintain consistent configurations throughout their Azure deployments.

Here are some key points about Azure Policy:
1. Policy Definitions: Azure Policy uses policy definitions to define rules and requirements for Azure resources. These policy definitions are written using JSON format and can be created and managed through the Azure portal, Azure PowerShell, Azure CLI, or Azure Resource Manager templates.
2. Policy Assignments: After creating policy definitions, you can assign them to specific Tenant, Management Group, Azure subscriptions, resource groups, or individual resources. This allows you to apply the policies at the desired scope and enforce the defined rules on those resources.
3. Compliance Assessment: Azure Policy continuously evaluates the compliance of your resources against the assigned policies. It provides a compliance report that helps you identify non-compliant resources and understand the level of adherence to your organizational policies.
4. Built-in and Custom Policies: Azure Policy offers a range of built-in policy definitions that cover various Azure services and compliance requirements. Additionally, you can create custom policy definitions to address specific needs unique to your organization.
5. Remediation and Enforcement: Azure Policy provides flexibility in handling non-compliant resources. You can choose to deny resource creation or modification that violates policies, audit and log non-compliant resources without enforcement, or automatically remediate non-compliant resources to bring them into compliance.
6. Integration with Azure Resource Manager: Azure Policy integrates seamlessly with Azure Resource Manager, allowing you to apply policies during resource deployments and manage policy compliance alongside resource management tasks.
7. Policy Insights and Reporting: Azure Policy provides detailed insights and reporting on policy compliance across your Azure resources. You can view compliance trends, drill down into specific policy violations, and gain visibility into the overall health of your environment.

For more details visit https://learn.microsoft.com/en-in/azure/governance/policy/overview

There are many in-built policies in Azure which can be used. However, these policies cannot be modified. So it's better to create custom policies with below policy standards. It helps in managing policies in a better way.

## Custom Policy Standards 
**Clear Objective**: Define a clear purpose for your custom policy. Know what specific governance or compliance requirement it addresses.
**Parameterization**: Use policy parameters for flexibility and reusability across different scenarios. Always set a default value (ideally a value which will work for most of the scenario) for a parameter to simplify assignment deployment.
**Use Exception Tag**: Add a rule in the policy using tag to exclude policy for a resource. Value for this tag can be passed as parameter. This parameter is used to trigger whether the policy needs to take effect or not. If any *resource* or parent *resource group* has this value present in the *tag* named as *exceptiontag* the policy will not trigger.
**Consistency**: Maintain consistency across naming conventions, policy structure, and design principles.
**Clear Naming**: Use descriptive names for policies that reflect their intent.
**Version Control**: Implement version control for policies to track changes and maintain a history.
**Documentation**: Document policy intent, use cases, and implementation details for easy reference.
**Thorough Testing**: Test policies in a controlled environment before applying them to production resources.
**Community Policies**: Explore Azure Policy initiatives from the community and adapt them as needed.
**Iterative Approach**: Refine policies iteratively based on feedback and practical experience.
**Educate Users**: Educate users on policy implications, compliance, and their responsibilities.

## Sample Policy
Let's define some policies to achieve below purposes

1. Generic: Ensuring some org specific standards like Resource Naming, Allowed Locations, Allowed VM Images etc.,
2. Security: Ensure TLS for storage/application gateway etc., Enabling soft delete for Key Vault/Storage etc., Configuring firewall,VNet for PaaS services, Configuring SQL Server Security settings, Configuring NSG/NIC etc.,
3. Tag: Adding Tag automatically on resource creation
4. Cost: Enable Windows Hybrid Benefits, VM Size/Type restriction etc.,
5. Monitoring: Configure and forward Diagnostic/Activity Logs to central location, Enable Network Watcher etc.,


*In addition to the Azure documentation, I have utilized various online articles from the internet to create these policies. I am genuinely thankful for their valuable assistance. Among them, a few notable ones are [Tao Yang](https://blog.tyang.org/), [Sam Cogan](https://samcogan.com/)*.