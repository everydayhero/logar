resource "aws_iam_policy" "es" {
  name = "${var.name}Access"
  description = "Allows listing EC2 instances. Used by elasticsearch for cluster discovery"
  policy = <<POLICY
{
  "Statement": [
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

  lifecycle {
    ignore_changes = ["name", "description"]
  }
}

resource "aws_iam_policy_attachment" "es" {
  name = "${var.name}Attachment"
  roles = ["${aws_iam_role.es.name}"]
  policy_arn = "${aws_iam_policy.es.arn}"
}

resource "aws_iam_role" "es" {
  name = "${var.name}Node"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
POLICY

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["name"]
  }
}

resource "aws_iam_instance_profile" "es" {
  name = "${var.name}Node"
  roles = ["${aws_iam_role.es.name}"]

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["name"]
  }
}

resource "aws_iam_role" "stats" {
  name = "${var.name}Stats"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_iam_role_policy" "stats" {
  name = "${var.name}Stats"
  role = "${aws_iam_role.stats.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "cloudwatch:PutMetricData"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY

  lifecycle {
    ignore_changes = ["name"]
  }
}
