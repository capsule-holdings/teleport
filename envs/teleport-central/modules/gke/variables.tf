variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "router_name" {
  description = "Router name"
  type        = string
}

variable "nat_ip_count" {
  description = "Number of NAT IPs to create"
  type        = number
  default     = 1
}
