resource "aws_security_group" "function" {
  name = "${var.name}Function"
  description = "Allows function access to elasticsearch"

  vpc_id = "${var.vpc_id}"

  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = ["${module.elasticsearch.security_group_id}"]
  }

  egress {
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"
    security_groups = ["${module.elasticsearch.security_group_id}"]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["name"]
  }
}
