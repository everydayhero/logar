module "curator" {
  source = "github.com/everydayhero/npm-lambda-packer"

  package = "logar-curator"
  version = "1.0.1"

  environment = <<ENVIRONMENT
ENDPOINT=http://${module.elasticsearch.dns_name}:9200
MAX_INDEX_AGE=${var.index_retention}
EXCLUDED_INDICES="${var.excluded_indices}"
ENVIRONMENT
}

resource "aws_lambda_function" "curator" {
  function_name = "${var.name}Curator"
  handler = "index.handler"
  filename = "${module.curator.filepath}"
  timeout = 300
  runtime = "nodejs4.3"

  role = "${aws_iam_role.function.arn}"

  vpc_config {
    subnet_ids = ["${split(",", var.subnet_ids)}"]
    security_group_ids = ["${aws_security_group.function.id}"]
  }

  lifecycle {
    ignore_changes = ["function_name"]
  }
}

resource "aws_cloudwatch_event_rule" "curate_daily" {
  name = "${var.name}CurateDaily"
  schedule_expression = "rate(1 day)"

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_cloudwatch_event_target" "curator" {
  rule = "${aws_cloudwatch_event_rule.curate_daily.name}"
  arn = "${aws_lambda_function.curator.arn}"
  target_id = "${aws_lambda_function.curator.function_name}"
}

resource "aws_lambda_permission" "grant_daily_curation" {
  statement_id = "AllowEventToInvokeLogsCurator"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.curator.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.curate_daily.arn}"
}

