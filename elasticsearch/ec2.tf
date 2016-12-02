resource "aws_elb" "es" {
  connection_draining = true
  cross_zone_load_balancing = true

  name = "${replace(lower(var.name), "e[^a-z0-9]+/", "-")}"
  subnets = ["${split(",", var.subnet_ids)}"]
  internal = "${var.internal_elb}"

  security_groups = ["${aws_security_group.elb.id}"]
  instances = ["${aws_instance.es.*.id}"]

  listener {
    instance_port     = 9200
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 9200
    instance_protocol = "http"
    lb_port           = 9200
    lb_protocol       = "http"
  }

  health_check {
    target              = "HTTP:9200/_cluster/health"
    healthy_threshold   = 10
    unhealthy_threshold = 10
    interval            = 300
    timeout             = 60
  }

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_instance" "es" {
  count           = "${var.cluster_size}"
  instance_type   = "${var.instance_type}"
  ami             = "${var.image_id}"
  key_name        = "${var.key_name}"
  subnet_id       = "${element(split(",", var.subnet_ids), count.index)}"

  iam_instance_profile = "${aws_iam_instance_profile.es.id}"

  user_data = "${data.template_file.es.rendered}"
  vpc_security_group_ids = ["${aws_security_group.es.id}"]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "${var.volume_size_root}"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp2"
    volume_size           = "${var.volume_size_data}"
    delete_on_termination = false
  }

  ephemeral_block_device {
    device_name  = "/dev/sdb"
    virtual_name = "ephemeral0"
  }

  tags {
    Role = "${var.name}"
    Name = "${var.name}-${count.index}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "es_low_storage" {
  alarm_name = "${var.name}LowStorage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = 2
  metric_name = "FreeStorage"
  namespace = "${var.name}"
  period = 900
  statistic = "Average"
  alarm_description = "Increase the elasticsearch cluster when there is less than ${var.scaling_free_storage_threshold}% free storage capacity"
  threshold = "${(var.volume_size_data * 1000000000.0) * (var.scaling_free_storage_threshold / 100.0)}"
}

data "template_file" "es" {
  template = "${file("${path.module}/user-data.txt")}"

  vars {
    version = "${var.version}"
    security_groups = "${aws_security_group.es.id}"
    cluster_name = "${var.name}"
    minimum_master_nodes = "${format("%d", (var.cluster_size / 2) + 1)}"
  }
}
