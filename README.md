# Azure Automation for Starting and Stopping Virtual Machines

This Terraform project automates the start and stop operations of Azure Virtual Machines (VMs) based on specific tags using Azure Automation. **For additional resources, examples, and community engagement**, check out the portal [Cloudymos](https://cloudymos.com) :cloud:.

## Prerequisites

Before you begin, make sure you have the following:

- Azure subscription
- Azure CLI installed and authenticated
- Terraform installed

## Configuration

### Authentication Variables

Make sure to set the following authentication variables in your environment:

- `arm_client_id`: Azure Active Directory (AAD) application client ID
- `arm_client_secret`: AAD application client secret
- `arm_tenant_id`: AAD tenant ID
- `subscription_id`: Azure subscription ID

### Code Variables

You can customize the following variables in `variables.tf` according to your requirements:

- `tag_name`: The name of the tag to validate when starting VMs. Default is "Auto".
- `tag_value`: The value of the tag to validate when starting VMs. Default is "Start-Stop-VMs".

## Structure

- **start-stop-vm.tf**: Defines Azure resources for automation, including resource group, automation account, runbooks, and schedules.
- **scripts/start-vms.ps1**: PowerShell script to start VMs based on specified tags.
- **scripts/stop-vms.ps1**: PowerShell script to stop VMs based on specified tags.
- **variables.tf**: Contains input variables used in the Terraform configuration.

## Usage

1. Set the authentication variables in your environment.
2. Customize the code variables in `variables.tf` if needed.
3. Run `terraform init` to initialize the project.
4. Run `terraform apply` to create Azure resources and deploy the automation.
5. Verify that the VMs are started and stopped as per the specified schedule.

## Alerts and Notifications

This project includes metric alerts for successful and failed runbook executions. Notifications are sent via email using Azure Monitor Action Groups.

## Maintenance

- **Update the schedules** as needed following azure documentations and patterns.
- Monitor alerts and notifications regularly to ensure proper functioning of automation.

## License
This project is licensed under the MIT License - see the [MIT License](https://opensource.org/licenses/MIT) file for details.

## Contributing
Contributions are welcome! Please follow the guidance below for details on how to contribute to this project:
1. Fork the repository
2. Create a new branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Open a pull request