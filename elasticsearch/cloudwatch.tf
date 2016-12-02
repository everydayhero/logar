resource "aws_cloudwatch_event_rule" "poll_stats_every_5_mins" {
  name = "${var.name}StatsPoll"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "stats" {
  rule = "${aws_cloudwatch_event_rule.poll_stats_every_5_mins.name}"
  arn = "${aws_lambda_function.stats.arn}"
  target_id = "${var.name}Stats"
}
