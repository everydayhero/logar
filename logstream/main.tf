variable "access_key" {
  default = ""
  description = "The AWS access key"
}

variable "secret_key" {
  default = ""
  description = "The AWS secret key"
}

variable "region" {
  default = "us-east-1"
  description = "The AWS region"
}

variable "shards" {
  default = 1
  description = "The number of shards for the Kinesis stream"
}

variable "name" {
  default = "Logstream"
}

resource "aws_iam_policy" "logstream" {
  name = "${var.name}KinesisAccess"
  description = "Allow reading from ${aws_kinesis_stream.logstream.name} Kinesis stream"
  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "kinesis:GetRecords",
        "kinesis:GetShardIterator",
        "kinesis:DescribeStream"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_kinesis_stream.logstream.arn}"
      ]
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_kinesis_stream" "logstream" {
  name = "${var.name}"
  shard_count = "${var.shards}"

  lifecycle {
    ignore_changes = ["name"]
  }
}

output "name" {
  value = "${aws_kinesis_stream.logstream.name}"
}

output "policy_arn" {
  value = "${aws_iam_policy.logstream.arn}"
}
