output "role_name" {
  value = "${aws_iam_role.ls.name}"
}

output "ip" {
  value = "${aws_instance.ls.private_ip}"
}
