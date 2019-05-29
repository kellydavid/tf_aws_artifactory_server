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

  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y docker
service docker start
docker run -P -d -p 80:80 nginxdemos/hello
EOF
}


locals {
  name        = "complete-ecs"
  environment = "dev"

  # This is the convention we use to know what belongs to each other
//  ec2_resources_name = "${local.name}-${local.environment}"
}

//module "vpc" {
//  source = "terraform-aws-modules/vpc/aws"
//
//  name = "${local.name}"
//
//  cidr = "10.1.0.0/16"
//
//  azs             = ["eu-west-1a", "eu-west-1b"]
//  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
//  public_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]
//
//  enable_nat_gateway = true
//  single_nat_gateway = true
//
//  tags = {
//    Environment = "${local.environment}"
//    Name        = "${local.name}"
//  }
//}

#----- ECS --------
resource "aws_ecs_cluster" "this" {
  name = "${var.name}"
  tags = "${var.tags}"
}

module "ec2-profile" {
  source = "./modules/ecs-instance-profile"
  name   = "${var.name}"
}

#----- ECS  Services--------

module "hello-world" {
  source     = "./modules/service-hello-world"
  cluster_id = "${aws_ecs_cluster.this.id}"
}

#----- ECS  Resources--------

#For now we only use the AWS ECS optimized ami <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html>
data "aws_ami" "amazon_linux_ecs" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

module "this" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "${var.name}"

  # Launch configuration
  lc_name = "${var.name}"

  image_id             = "${data.aws_ami.amazon_linux_ecs.id}"
  instance_type        = "t2.micro"
  security_groups      = ["${aws_security_group.server_sg.id}"]
  iam_instance_profile = "${module.ec2-profile.this_iam_instance_profile_id}"
  user_data            = "${data.template_file.user_data.rendered}"

  # Auto scaling group
  asg_name                  = "${var.name}"
  vpc_zone_identifier       = "${var.instance_subnet_ids}"
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "${local.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = "${local.name}"
      propagate_at_launch = true
    },
  ]
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user-data.sh")}"

  vars {
    cluster_name = "${local.name}"
  }
}
