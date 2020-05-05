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

variable "subnet_ids" {
  type = list
}


variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

variable "app_image" {
  description = "Docker image to run in the ECS cluster"
  default     = "adongy/hostname-docker:latest"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 80
}
