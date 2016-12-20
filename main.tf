provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

data "aws_ami" "es" {
  most_recent = true
  executable_users = ["all", "self"]

  filter {
    name = "name"
    values = ["*/hvm-ssd/ubuntu-xenial-16.04-amd64-server*"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "hypervisor"
    values = ["xen"]
  }

  filter {
    name = "state"
    values = ["available"]
  }

  filter {
    name = "root-device-type"
    values = ["ebs"]
  }
}

module "elasticsearch" {
  source             = "./elasticsearch"
  name               = "${var.name}Elasticsearch"
  access_key         = "${var.access_key}"
  secret_key         = "${var.secret_key}"
  region             = "${var.region}"
  key_name           = "${var.key_name}"
  subnet_ids         = "${split(",", var.subnet_ids)}"
  vpc_id             = "${var.vpc_id}"
  instance_type      = "${coalesce(var.es_instance_type, var.instance_type)}"
  image_id           = "${coalesce(var.image_id, data.aws_ami.es.id)}"
  cluster_size       = "${var.cluster_size}"
  volume_size_data   = "${var.volume_size}"
  version            = "${var.version}"
}

module "logstash" {
  source             = "./logstash"
  name               = "${var.name}Logstash"
  access_key         = "${var.access_key}"
  secret_key         = "${var.secret_key}"
  region             = "${var.region}"
  key_name           = "${var.key_name}"
  subnet_id          = "${element(split(",", var.subnet_ids), 0)}"
  vpc_id             = "${var.vpc_id}"
  instance_type      = "${coalesce(var.ls_instance_type, var.instance_type)}"
  image_id           = "${coalesce(var.image_id, data.aws_ami.es.id)}"
  version            = "${var.version}"
  logstream_name     = "${module.logstream.name}"
  cluster_name       = "${module.elasticsearch.cluster_name}"
  minimum_master_nodes = "${module.elasticsearch.minimum_master_nodes}"
  elasticsearch_security_group_id = "${module.elasticsearch.node_security_group_id}"
}

module "logstream" {
  source             = "./logstream"
  name               = "${var.name}Logstream"
  access_key         = "${var.access_key}"
  secret_key         = "${var.secret_key}"
  region             = "${var.region}"
  shards             = "${coalesce(var.shards, (var.cluster_size + (var.cluster_size % 2)) / 2)}"
}

