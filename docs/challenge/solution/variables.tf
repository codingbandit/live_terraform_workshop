variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "terraform_lab_1"
}

variable "preferred_location" {
  description = "Preferred region for deploying services"
  type        = string
  default     = "West US"
}