variable "name" {
  type = string
  default = "testytest"
}

variable "container_name" {
  type = string
  default = "testytest"
}

variable "vpc_id" {
  type = string
}

variable "cidr_blocks" {
  type = list
}

variable "subnets" {
  
}

variable "from_port" {
  
}

variable "to_port" {
  
}

variable "protocol" {
  default = "tcp"
}

variable "listener_url" {
  type = string
}

variable "family" {
  type = string
}

variable "azs" {
  type = string
}
