module "stats" {
  source = "github.com/everydayhero/npm-lambda-packer"

  package = "logar-stats"
  version = "1.0.4"

  environment = <<ENVIRONMENT
ENDPOINT=http://${aws_elb.es.dns_name}:9200
NAMESPACE=${var.name}
ENVIRONMENT
}

resource "aws_lambda_function" "stats" {
  function_name = "${var.name}Stats"
  handler = "index.handler"
  filename = "${module.stats.filepath}"
  timeout = 30
  runtime = "nodejs4.3"

  role = "${aws_iam_role.stats.arn}"

  vpc_config {
    subnet_ids = ["${split(",", var.subnet_ids)}"]
    security_group_ids = ["${aws_security_group.stats.id}"]
  }

  lifecycle {
    ignore_changes = ["function_name"]
  }
}

resource "aws_lambda_permission" "grant_poll_stats" {
  statement_id = "AllowEventToInvokeLogsStats"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.stats.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.poll_stats_every_5_mins.arn}"
}

