output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "private_subnet_id" {
  value = "${aws_subnet.private_subnet.*.id}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public_subnet.*.id}"
}

output "security_groups_ids" {
  value = ["${aws_security_group.default.id}"]
}