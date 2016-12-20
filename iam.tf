resource "aws_iam_policy_attachment" "ls_logstream" {
  name = "${var.name}ReadKinesisStream"
  roles = ["${module.logstash.role_name}"]
  policy_arn = "${module.logstream.policy_arn}"
}

resource "aws_iam_role" "function" {
  name = "${var.name}Function"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
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

resource "aws_iam_role_policy" "function" {
  name = "${var.name}FunctionExecution"
  role = "${aws_iam_role.function.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "kinesis:GetRecords",
        "kinesis:GetShardIterator",
        "kinesis:DescribeStream",
        "kinesis:ListStreams"
      ],
      "Resource": "*"
    }
  ]
}
POLICY

  lifecycle {
    ignore_changes = ["name"]
  }
}

