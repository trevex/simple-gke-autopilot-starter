variable "project" {
  type     = string
  nullable = false
}

variable "chart_version" {
  type = string
}

variable "dns_zones" {
  type = set(string)
}
