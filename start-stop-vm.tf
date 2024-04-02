# CREATE AUTOMATION ACCOUNT

resource "azurerm_resource_group" "start_stop_vms_rg" {
  name     = "start-stop-vms-rg"
  location = "eastus"
}

resource "azurerm_automation_account" "start_stop_vms_aa" {
  name                = "start-stop-vms-automation-account"
  location            = azurerm_resource_group.start_stop_vms_rg.location
  resource_group_name = azurerm_resource_group.start_stop_vms_rg.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }
}

# SET UP ACCESS

data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "aa_system_id" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_automation_account.start_stop_vms_aa.identity[0].principal_id
}

# AZURE AUTOMATION ACCOUNT RUNBOOK

## start vm
data "local_file" "start_vms_file" {
  filename = "${path.module}/scripts/start-vms.ps1"
}

resource "azurerm_automation_runbook" "start_vms_runbk" {
  name                    = "start-vms-runbook"
  location                = azurerm_resource_group.start_stop_vms_rg.location
  resource_group_name     = azurerm_resource_group.start_stop_vms_rg.name
  automation_account_name = azurerm_automation_account.start_stop_vms_aa.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Runbook to start VMs"
  runbook_type            = "PowerShell"

  content = data.local_file.start_vms_file.content
}

## stop vm

data "local_file" "stop_vms_file" {
  filename = "${path.module}/scripts/stop-vms.ps1"
}

resource "azurerm_automation_runbook" "stop_vms_runbk" {
  name                    = "stop-vms-runbook"
  location                = azurerm_resource_group.start_stop_vms_rg.location
  resource_group_name     = azurerm_resource_group.start_stop_vms_rg.name
  automation_account_name = azurerm_automation_account.start_stop_vms_aa.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Runbook to stop VMs"
  runbook_type            = "PowerShell"

  content = data.local_file.stop_vms_file.content
}

# AZURE AUTOMATION ACCOUNT SCHEDULE 

## start vm schecule
resource "azurerm_automation_schedule" "start_vm_schedule" {
  name                    = "start-vm-schedule"
  resource_group_name     = azurerm_resource_group.start_stop_vms_rg.name
  automation_account_name = azurerm_automation_account.start_stop_vms_aa.name
  frequency               = "Day"
  interval                = 1
  description             = "Daily trigger to start VMs at 07h EST"
  start_time              = "2024-04-01T07:00:00-05:00"
  timezone                = "America/New_York"
}
resource "azurerm_automation_job_schedule" "start_vm_job_schedule" {
  resource_group_name     = azurerm_resource_group.start_stop_vms_rg.name
  automation_account_name = azurerm_automation_account.start_stop_vms_aa.name
  schedule_name           = azurerm_automation_schedule.start_vm_schedule.name
  runbook_name            = azurerm_automation_runbook.start_vms_runbk.name

  parameters = {
    tag_name  = var.tag_name
    tag_value = var.tag_value
  }
}

## stop vm schecule
resource "azurerm_automation_schedule" "stop_vm_schedule" {
  name                    = "stop-vm-schedule"
  resource_group_name     = azurerm_resource_group.start_stop_vms_rg.name
  automation_account_name = azurerm_automation_account.start_stop_vms_aa.name
  frequency               = "Day"
  interval                = 1
  description             = "Daily trigger to stop VMs at 20h EST"
  start_time              = "2024-04-01T20:00:00-05:00"
  timezone                = "America/New_York"
}
resource "azurerm_automation_job_schedule" "stop_vm_job_schedule" {
  resource_group_name     = azurerm_resource_group.start_stop_vms_rg.name
  automation_account_name = azurerm_automation_account.start_stop_vms_aa.name
  schedule_name           = azurerm_automation_schedule.stop_vm_schedule.name
  runbook_name            = azurerm_automation_runbook.stop_vms_runbk.name

  parameters = {
    tag_name  = var.tag_name
    tag_value = var.tag_value
  }
}

# CREATE NOTIFICATION

resource "azurerm_monitor_action_group" "email_action_group" {
  name                = "RunbookExecutionEmailAction"
  resource_group_name = azurerm_resource_group.start_stop_vms_rg.name
  short_name          = "EmailAction"

  email_receiver {
    name                    = "EmailReceiver"
    email_address           = "b.olimpio@outlook.com"
    use_common_alert_schema = true
  }
}

# Resource to create a metric alert for successful runbook execution
resource "azurerm_monitor_metric_alert" "runbook_success_alert" {
  name                = "RunbookSuccessAlert"
  resource_group_name = azurerm_resource_group.start_stop_vms_rg.name
  description         = "Alert triggered when a runbook execution succeeds"
  severity            = 3
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Automation/automationAccounts"
    metric_name      = "TotalJob"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
    dimension {
      name     = "Status"
      operator = "Include"
      values   = ["Completed"]
    }
    dimension {
      name     = "Runbook"
      operator = "Include"
      values   = [azurerm_automation_runbook.stop_vms_runbk.name,azurerm_automation_runbook.start_vms_runbk.name]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_action_group.id
  }

  scopes = [azurerm_automation_account.start_stop_vms_aa.id]
}

# Resource to create a metric alert for failed runbook execution
resource "azurerm_monitor_metric_alert" "runbook_failure_alert" {
  name                = "RunbookFailureAlert"
  resource_group_name = azurerm_resource_group.start_stop_vms_rg.name
  description         = "Alert triggered when a runbook execution fails"
  severity            = 3
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Automation/automationAccounts"
    metric_name      = "TotalJob"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
    dimension {
      name     = "Status"
      operator = "Include"
      values   = ["Failed"]
    }
    dimension {
      name     = "Runbook"
      operator = "Include"
      values   = [azurerm_automation_runbook.stop_vms_runbk.name,azurerm_automation_runbook.start_vms_runbk.name]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_action_group.id
  }

  scopes = [azurerm_automation_account.start_stop_vms_aa.id]
}
