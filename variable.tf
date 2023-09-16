variable "client_id"{
  type=string
}
variable "client_secret"{
  type=string
}
variable "subscription_id"{
  type=string
}
variable "tenant_id"{
  type=string
}

variable "owner"{
  type        = string
  description = "Owner of the application, workload, or service"
  default     = "mcti"
}

variable "env"{
  type        = string
  description =  "Deployment environment of the application, workload, or service"
  default     = "lab"
}

variable "region"{
  type        = string
  description = "Azure region where the resource is deployed"
  default     = "central-canada"
}

variable "name" {
  type        = string
  description = "Name of the application, workload, or service"
  default     = "vmscaleset"
}

variable "convention" {
  type        = string
  description = "Define naming convention"
  default     = "rg-${name}-${owner}-${env}-${region}"
}
variable "resource_group_name" {
   description  = "Name of the resource group in which resources will be created"
   type         = string
   default      = "rg-${convention}"
}

variable "location" {
   type         =  string
   default      = "Canada Central"
   description  = "Location where resources will be created"
}

variable "tags" {
   description = "Map of the tags to use for the resources that are deployed"
   type        = map(string)
   default     = {
      environment = "mcitlab"
   }
}

variable "application_port" {
   description = "Port that is exposed to the external load balancer"
   default     = 80
}

variable "admin_user" {
   description = "User name to use as the admin account on the VMs that will be part of the VM scale set"
   type = string
}

variable "admin_password" {
   description  = "Default password for admin account"
   type         = string
}
