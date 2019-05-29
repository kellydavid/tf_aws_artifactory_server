variable name {
  type = "string"
  default = "artifactory-server"
  description = "The name of the artifactory server. Defaults to artifactory-server"
}

variable tags {
  type = "map"
  description = "A map of tags to apply to all resources."
}

variable ec2_instance_size {
  type = "string"
  default = "t2.micro"
  description = "The ec2 instance size."
}

variable vpc_id {
  type = "string"
  description = "The vpc id."
}

variable vpc_subnet_id {
  type = "string"
  description = "Subnet id."
}

variable instance_subnet_ids {
  type = "list"
  description = "A list of subnet ids which instances can connect to."
}

variable ssh_key_name {
  type = "string"
  description = "The ec2 ssh key name."
}

variable ingress_cidr_blocks {
  type = "list"
  description = "A list of allowed cidr blocks for ingress traffic."
}

variable associate_public_ip_address {
  default = false
  description = "Set to true if a public ip address should be associated with the ec2 instance."
}
