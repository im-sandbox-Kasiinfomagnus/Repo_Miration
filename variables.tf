variable "short_prefix" {
  type = string
}

variable "long_prefix" {
  type = string
}

variable "role" {
  type = string
}


variable "tags" {
  type = map(any)
}

variable "content" {
  type = string
}

variable "contents" {
  type    = map(any)
  default = {}
}

variable "retention_in_days" {
  type = number
}

variable "timeout" {
  type    = number
  default = 3
}

variable "modules" {
  type    = list(string)
  default = []
}

variable "memory_size" {
  type    = number
  default = null
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "environment_variables" {
  type    = any
  default = null
}

variable "subnet_ids" {
  type    = any
  default = null
}

variable "security_group_ids" {
  type    = any
  default = null
}

variable "layers" {
  type    = list(any)
  default = []
}

variable "vpc_id" {
  type    = string
  default = null
}
