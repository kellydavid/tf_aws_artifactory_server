provider "aws" {
  region = "eu-west-1"
  version = "2.7.0"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

module artifactory_server {
  source = "../"
  ingress_cidr_blocks = "${var.allowed_cidr_blocks}"
  ssh_key_name = "artifactory_server_key"
  vpc_id = "${data.aws_vpc.default.id}"
  vpc_subnet_id = "${element(data.aws_subnet_ids.all.ids, 0)}"
  associate_public_ip_address = true
  tags = {
    artifactory = "true"
  }
}
