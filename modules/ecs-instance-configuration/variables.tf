variable name {
  type = "string"
  description = "The name of the artifactory server. Defaults to artifactory-server"
}

variable tags {
  type = "map"
  description = "A map of tags to apply to all resources."
}

variable instance_subnet_ids {
  type = "list"
  description = "A list of subnet ids which instances can connect to."
}

variable ingress_cidr_blocks {
  type = "list"
  description = "A list of allowed cidr blocks for ingress traffic."
}

variable vpc_id {
  type = "string"
  description = "The vpc id."
}
