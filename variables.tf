#Authentication variables
variable "arm_client_id" {}

variable "arm_client_secret" {}

variable "arm_tenant_id" {}

variable "subscription_id" {}

#Code variables

variable "tag_name" {
  description = "The name of the tag to validate when starting VMs."
  default = "Auto"
  type = string
}

variable "tag_value" {
  description = "The value of the tag to validate when starting VMs."
  default = "Start-Stop-VMs"
  type = string
}