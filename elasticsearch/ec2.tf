resource "aws_elb" "es" {
  connection_draining = true
  cross_zone_load_balancing = true

  name = "${replace(lower(var.name), "e[^a-z0-9]+/", "-")}"
  subnets = ["${data.aws_subnet.selected.*.id}"]
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
  subnet_id       = "${element(data.aws_subnet.selected.*.id, count.index)}"

  iam_instance_profile = "${aws_iam_instance_profile.es.id}"

  user_data = "${data.template_file.es.rendered}"
  vpc_security_group_ids = ["${aws_security_group.es.id}"]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "${var.volume_size_root}"
    delete_on_termination = true
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

resource "aws_ebs_volume" "data" {
  count = "${var.cluster_size}"
  availability_zone = "${element(data.aws_subnet.selected.*.availability_zone, count.index)}"
  type = "gp2"
  size = "${var.volume_size_data}"

  tags {
    Name = "${var.name}Data"
  }
}

resource "aws_volume_attachment" "data" {
  count = "${var.cluster_size}"
  instance_id = "${element(aws_instance.es.*.id, count.index)}"
  volume_id = "${element(aws_ebs_volume.data.*.id, count.index)}"

  device_name = "/dev/sdf"

  force_detach = true
  skip_destroy = true
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
