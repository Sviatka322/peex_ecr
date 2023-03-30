resource "aws_iam_user" "ecr_user" {
    name = "peex_ecr_user"

    tags = var.aws_tags
}

resource "aws_iam_user_policy" "ecr_user" {
    name = "peex_ecr_policy"
    user = aws_iam_user.ecr_user.name
    policy = templatefile("${path.root}/iam_templates/ecr_iam_policy.tpl", {repository_arn = aws_ecr_repository.peex.arn})
}