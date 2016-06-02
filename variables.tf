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

variable "instance_type" {
  default = "m3.medium"
  description = "The EC2 instance type to use"
}

variable "volume_size" {
  default = 100
  description = "Size of the cluster"
}

variable "cluster_size" {
  default = 3
  description = "Size of the cluster"
}

variable "index_retention" {
  default = 14
  description = "The number of days to retain elasticsearch indices"
}

variable "excluded_indices" {
  default = ".kibana"
  description = "Indicies to not cull"
}

variable "shards" {
  default = ""
  description = "The number of shards allocated for kinesis stream. Defaults to half the cluster size."
}
