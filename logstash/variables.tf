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

variable "key_name" {
  description = "The key name for the instances"
}

variable "subnet_ids" {
  description = "The subnet ID to use for the instances"
}

variable "vpc_id" {
  description = "The VPC ID"
}

variable "image_id" {
  description = "The Debian-based AMI to use"
}

variable "instance_type" {
  default = "m3.medium"
  description = "The EC2 instance type to use"
}

variable "volume_size_root" {
  default = 50
  description = "Size of the cluster"
}

variable "name" {
  default = ""
  description = "The name of the Logstash instance"
}

variable "version" {
  default = "5.0"
  description = "The version of Logstash to use"
}

variable "logstream_name" {
  description = "The logstream name"
}

variable "cluster_name" {
  default = ""
  description = "The elasticsearch cluster name. Defaults to name"
}

variable "minimum_master_nodes" {
  default = 1
  description = "The minimum number of elasticsearch master nodes needed"
}

variable "elasticsearch_security_group_id" {
  description = "The security group id for the elasticsearch cluster"
}
