output "repository_url" {
  value = "${aws_codecommit_repository.source_code.clone_url_ssh}"
}
