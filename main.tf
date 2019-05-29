#----- ECS --------
resource "aws_ecs_cluster" "this" {
  name = "${var.name}"
  tags = "${var.tags}"
}

#----- ECS  Services--------
module "hello-world" {
  source     = "./modules/service-hello-world"
  cluster_id = "${aws_ecs_cluster.this.id}"

}

#----- ECS  Resources--------

module ecs_resources {
  source = "./modules/ecs-instance-configuration"
  name = "${var.name}"
  ingress_cidr_blocks = "${var.ingress_cidr_blocks}"
  instance_subnet_ids = "${var.instance_subnet_ids}"
  vpc_id = "${var.vpc_id}"
  tags = "${var.tags}"
}
