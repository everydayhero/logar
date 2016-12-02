resource "aws_security_group" "elb" {
  name = "${var.name}LoadBalancer"
  description = "Allows the load balancer to communicate with Elasticsearch nodes"

  vpc_id = "${var.vpc_id}"

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["name", "description"]
  }
}

resource "aws_security_group_rule" "elb_default" {
  type        = "ingress"
  from_port   = 9200
  to_port     = 9200
  protocol    = "tcp"
  cidr_blocks = ["${var.vpc_cidr}"]
  security_group_id = "${aws_security_group.elb.id}"
}

resource "aws_security_group_rule" "elb_http" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["${var.vpc_cidr}"]
  security_group_id = "${aws_security_group.elb.id}"
}

resource "aws_security_group_rule" "elb_es" {
  type        = "egress"
  from_port   = 9200
  to_port     = 9200
  protocol    = "tcp"
  source_security_group_id = "${aws_security_group.es.id}"
  security_group_id = "${aws_security_group.elb.id}"
}

resource "aws_security_group" "es" {
  name = "${var.name}Node"
  description = "Allows inter-node communication between Elasticsearch nodes"

  vpc_id = "${var.vpc_id}"

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["name", "description"]
  }
}

resource "aws_security_group_rule" "es_elb" {
  type        = "ingress"
  from_port   = 9200
  to_port     = 9200
  protocol    = "tcp"
  security_group_id = "${aws_security_group.es.id}"
  source_security_group_id = "${aws_security_group.elb.id}"
}

resource "aws_security_group_rule" "es_to_cluster_9200" {
  type        = "ingress"
  from_port   = 9200
  to_port     = 9200
  protocol    = "tcp"
  self        = true
  security_group_id = "${aws_security_group.es.id}"
}

resource "aws_security_group_rule" "es_to_cluster_9300" {
  type        = "ingress"
  from_port   = 9300
  to_port     = 9300
  protocol    = "tcp"
  self        = true
  security_group_id = "${aws_security_group.es.id}"
}

resource "aws_security_group_rule" "cluster_to_es_9200" {
  type        = "egress"
  from_port   = 9200
  to_port     = 9200
  protocol    = "tcp"
  self        = true
  security_group_id = "${aws_security_group.es.id}"
}

resource "aws_security_group_rule" "cluster_to_es_9300" {
  type        = "egress"
  from_port   = 9300
  to_port     = 9300
  protocol    = "tcp"
  self        = true
  security_group_id = "${aws_security_group.es.id}"
}

resource "aws_security_group_rule" "es_http" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.es.id}"
}

resource "aws_security_group_rule" "es_https" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.es.id}"
}


resource "aws_security_group" "stats" {
  name = "${var.name}Stats"
  description = "Allows stats lambda function to access elb"

  vpc_id = "${var.vpc_id}"

  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  egress {
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["name", "description"]
  }
}
