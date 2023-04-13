variable "parent_project" {
  type = string
}

variable "parent_zone_name" {
  type = string
}

variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = "Zone created and managed by terraform"
}

variable "fqdn" {
  type = string
}
