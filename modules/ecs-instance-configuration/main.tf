module "ec2-profile" {
  source = "./ecs-instance-profile"
  name   = "${var.name}"
}

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
  security_groups      = ["${aws_security_group.instance_security_group.id}"]
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
      key                 = "Cluster"
      value               = "${var.name}"
      propagate_at_launch = true
    },
  ]
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    cluster_name = "${var.name}"
  }
}

resource "aws_security_group" "instance_security_group" {
  name        = "${var.name}-ecs-instance-sg"
  description = "Allow inbound HTTP and HTTPS traffic. Allow outbound traffic."
  vpc_id      = "${var.vpc_id}"
  tags        = "${var.tags}"

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

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}