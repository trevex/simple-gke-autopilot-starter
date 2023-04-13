variable "project" {
  type     = string
  nullable = false
}

variable "name" {
  type     = string
  nullable = false
}

variable "namespace" {
  type     = string
  nullable = false
}

variable "roles" {
  type    = set(string)
  default = []
}
