variable "aws_tags" {
    type = map(string)
    default = {
      "Name" = "PeeX ECR repository",
      "Environment" = "PeeX"
    }
}