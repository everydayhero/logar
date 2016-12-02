output "cluster_name" {
  value = "${var.name}"
}

output "version" {
  value = "${var.version}"
}

output "dns_name" {
  value = "${aws_elb.es.dns_name}"
}

output "url" {
  value = "http://${aws_elb.es.dns_name}:9200"
}

output "security_group_id" {
  value = "${aws_security_group.elb.id}"
}

output "node_security_group_id" {
  value = "${aws_security_group.es.id}"
}

output "elb_security_group_id" {
  value = "${aws_security_group.elb.id}"
}

output "ip" {
  value = "${join(",", aws_instance.es.*.private_ip)}"
}

output "ip_addresses" {
  value = ["${aws_instance.es.*.private_ip}"]
}

output "minimum_master_nodes" {
  value = "${format("%d", (var.cluster_size / 2) + 1)}"
}
