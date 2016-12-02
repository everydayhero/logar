output "elasticsearch_url" {
  value = "${module.elasticsearch.dns_name}"
}

output "stream_name" {
  value = "${module.logstream.name}"
}

output "elasticsearch_ip" {
  value = "${module.elasticsearch.ip}"
}

output "logstash_ip" {
  value = "${module.logstash.ip}"
}
