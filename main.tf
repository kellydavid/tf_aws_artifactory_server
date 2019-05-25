data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

resource "aws_security_group" "server_sg" {
  name        = "${var.name}-server-sg"
  description = "Allow inbound artifactory server traffic. Allow ssh. Allow outbound traffic."
  vpc_id      = "${var.vpc_id}"
  tags = "${var.tags}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.ingress_cidr_blocks}"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.ingress_cidr_blocks}"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.ingress_cidr_blocks}"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


module ec2 {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "1.21.0"

  name                   = "${var.name}"
  instance_count         = 1

  ami                    = "${data.aws_ami.amazon_linux.image_id}"
  instance_type          = "${var.ec2_instance_size}"
  key_name               = "${var.ssh_key_name}"
  monitoring             = true
  vpc_security_group_ids = ["${aws_security_group.server_sg.id}"]
  subnet_id              = "${var.vpc_subnet_id}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  tags = "${var.tags}"

  root_block_device = [{
    volume_type = "gp2"
    volume_size = 10
  }]
}