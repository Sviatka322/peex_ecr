resource "aws_ecr_repository" "peex" {
    name = "peex"

    tags = var.aws_tags
}