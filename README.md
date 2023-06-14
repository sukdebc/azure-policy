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

## Sample Policy
Let's define some policies to acheive below purposes

1. Generic: Ensuring some org specific standards like Resource Naming, Allowed Locations, Allowed VM Images etc
2. Security: Ensure TLS for storage/application gateway etc, Enabling soft delete for Key Vault/Storage etc, Configuring firewall,VNet for PaaS services, Configuring SQL Server Security settings, Configuring NSG/NIC etc
3. Tag: Adding Tag automatically on resource creation
4. Cost: Enable Windows Hybrid Benefits, VM Size/Type restriction etc
5. Monitoring: Configure and forward Diganostic/Activity Logs to central location, Enable Network Watcher etc
