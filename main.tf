provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

module "elasticsearch" {
  source        = "github.com/everydayhero/terraform-elasticsearch"
  name          = "logs"
  access_key    = "${var.access_key}"
  secret_key    = "${var.secret_key}"
  region        = "${var.region}"
  key_name      = "${var.key_name}"
  subnet_ids    = "${var.subnet_ids}"
  vpc_id        = "${var.vpc_id}"
  instance_type = "${var.instance_type}"
  volume_size   = "${var.volume_size}"
  cluster_size  = "${var.cluster_size}"
}

resource "aws_iam_role" "function" {
  name = "LogsFunction"
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
}

resource "aws_iam_role_policy" "function" {
  name = "LogsFunctionExecution"
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
}

resource "aws_security_group" "function" {
  name = "LogsFunction"
  description = "Allows function access to elasticsearch"

  vpc_id = "${var.vpc_id}"

  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = ["${module.elasticsearch.security_group_id}"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_kinesis_stream" "logstream" {
  name = "Logstream"
  shard_count = "${(var.cluster_size + (var.cluster_size % 2)) / 2}"
}

resource "null_resource" "funnel" {
  triggers {
    elasticsearch_dns_name = "${module.elasticsearch.dns_name}"
  }

  provisioner "local-exec" {
    command = "./funnel/bin/build --endpoint='${module.elasticsearch.dns_name}' --output=../functions/funnel.zip"
  }
}

resource "aws_lambda_function" "funnel" {
  function_name = "LogsFunnel"
  handler = "index.handler"
  filename = "functions/funnel.zip"
  timeout = 30

  role = "${aws_iam_role.function.arn}"

  vpc_config {
    subnet_ids = ["${split(",", var.subnet_ids)}"]
    security_group_ids = ["${aws_security_group.function.id}"]
  }

  depends_on = ["null_resource.funnel"]
}

resource "aws_lambda_event_source_mapping" "logstream" {
  batch_size = 10000
  starting_position = "TRIM_HORIZON"

  function_name = "${aws_lambda_function.funnel.arn}"
  event_source_arn = "${aws_kinesis_stream.logstream.arn}"
}

resource "null_resource" "curator" {
  triggers {
    elasticsearch_dns_name = "${module.elasticsearch.dns_name}"
  }

  provisioner "local-exec" {
    command = "./curator/bin/build --endpoint='${module.elasticsearch.dns_name}' --max_index_age=${var.index_retention} --excluded_indices='${var.excluded_indices}' --output=../functions/curator.zip"
  }
}

resource "aws_lambda_function" "curator" {
  function_name = "LogsCurator"
  handler = "index.handler"
  filename = "functions/curator.zip"
  timeout = 30

  role = "${aws_iam_role.function.arn}"

  vpc_config {
    subnet_ids = ["${split(",", var.subnet_ids)}"]
    security_group_ids = ["${aws_security_group.function.id}"]
  }

  depends_on = ["null_resource.curator"]
}

output "dns_name" {
  value = "${module.elasticsearch.dns_name}"
}

output "stream_name" {
  value = "${aws_kinesis_stream.logstream.name}"
}
