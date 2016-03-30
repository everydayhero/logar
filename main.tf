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

resource "aws_iam_role" "stats" {
  name = "LogsStats"
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

resource "aws_iam_role_policy" "stats" {
  name = "LogsStats"
  role = "${aws_iam_role.stats.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1459302288332",
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

  egress {
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"
    security_groups = ["${module.elasticsearch.security_group_id}"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

module "stats" {
  source = "github.com/everydayhero/npm-lambda-packer"

  package = "logar-stats"
  version = "1.0.4"

  environment = <<ENVIRONMENT
ENDPOINT=http://${module.elasticsearch.dns_name}:9200
NAMESPACE=Logs
ENVIRONMENT
}

resource "aws_lambda_function" "stats" {
  function_name = "LogsStats"
  handler = "index.handler"
  filename = "${module.stats.filepath}"
  timeout = 30

  role = "${aws_iam_role.stats.arn}"

  vpc_config {
    subnet_ids = ["${split(",", var.subnet_ids)}"]
    security_group_ids = ["${aws_security_group.function.id}"]
  }
}

resource "aws_cloudwatch_event_rule" "poll_stats_every_5_mins" {
  name = "LogsStatsPoll"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "stats" {
  rule = "${aws_cloudwatch_event_rule.poll_stats_every_5_mins.name}"
  arn = "${aws_lambda_function.stats.arn}"
  target_id = "LogsStats"
}

resource "aws_lambda_permission" "grant_poll_stats" {
  statement_id = "AllowEventToInvokeLogsStats"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.stats.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.poll_stats_every_5_mins.arn}"
}

output "dns_name" {
  value = "${module.elasticsearch.dns_name}"
}

output "stream_name" {
  value = "${aws_kinesis_stream.logstream.name}"
}

