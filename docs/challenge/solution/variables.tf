variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "terraform_challenge"
}

variable "preferred_location" {
  description = "Preferred region for deploying services"
  type        = string
  default     = "East US"
}