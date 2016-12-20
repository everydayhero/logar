provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_iam_role" "ls" {
  name = "${var.name}"
  assume_role_policy = "${file("${path.module}/assume_role_policy.json")}"
}

resource "aws_iam_role_policy" "ls" {
  name = "${var.name}Policy"
  role = "${aws_iam_role.ls.id}"
  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "dynamodb:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:dynamodb:${var.region}:*:table/${var.name}"
      ]
    },
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_instance_profile" "ls" {
  name = "${var.name}"
  roles = ["${aws_iam_role.ls.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "ls" {
  instance_type   = "${var.instance_type}"
  ami             = "${var.image_id}"
  key_name        = "${var.key_name}"
  subnet_id       = "${var.subnet_id}"

  iam_instance_profile = "${aws_iam_instance_profile.ls.id}"

  user_data = "${data.template_file.ls.rendered}"
  vpc_security_group_ids = ["${var.elasticsearch_security_group_id}"]

  tags {
    Role = "${var.name}"
    Name = "${var.name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "ls" {
  template = "${file("${path.module}/user-data.txt")}"

  vars {
    cluster_name = "${var.cluster_name}"
    minimum_master_nodes = "${var.minimum_master_nodes}"
    security_groups = "${var.elasticsearch_security_group_id}"
    version = "${var.version}"
    logstream_name = "${var.logstream_name}"
    application_name = "${var.name}"
  }
}

