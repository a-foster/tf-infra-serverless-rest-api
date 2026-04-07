# Elastic Container Registry (ECR)
# Repository for storing Lambda container images

resource "aws_ecr_repository" "lambda_container" {
  name                 = "${var.project_name}-${var.function_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.function_name}"
      Environment = var.environment
      Purpose     = "Lambda container images"
    },
    var.tags
  )
}

resource "aws_ecr_lifecycle_policy" "lambda_container" {
  repository = aws_ecr_repository.lambda_container.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "lambda_container" {
  repository = aws_ecr_repository.lambda_container.name

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = concat(
      [
        {
          Sid    = "LambdaECRImageRetrievalPolicy"
          Effect = "Allow"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
          Action = [
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:SetRepositoryPolicy",
            "ecr:DeleteRepositoryPolicy",
            "ecr:GetRepositoryPolicy"
          ]
          Condition = {
            StringLike = {
              "aws:sourceArn" = "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:*"
            }
          }
        }
      ],
      var.github_actions_role_arn != null ? [
        {
          Sid    = "GitHubActionsECRPushPolicy"
          Effect = "Allow"
          Principal = {
            AWS = var.github_actions_role_arn
          }
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
          ]
        }
      ] : []
    )
  })
}
