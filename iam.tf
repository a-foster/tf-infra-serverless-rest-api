# IAM Roles and Policies
# Lambda execution role, GitHub OIDC provider, and GitHub Actions roles

# ============================================================================
# GitHub OIDC Provider (Optional - only created if github_org is provided)
# ============================================================================

resource "aws_iam_openid_connect_provider" "github" {
  count = local.enable_github_actions ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  tags = {
    Name        = "GitHub Actions OIDC Provider"
    Environment = var.environment
  }
}

# ============================================================================
# GitHub Actions Role - Application Repo (Optional)
# ============================================================================

data "aws_iam_policy_document" "github_actions_app_assume" {
  count = local.enable_github_actions ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo_app}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_app" {
  count = local.enable_github_actions ? 1 : 0

  name               = "${var.project_name}-github-actions-app"
  assume_role_policy = data.aws_iam_policy_document.github_actions_app_assume[0].json

  tags = {
    Name        = "${var.project_name}-github-actions-app"
    Environment = var.environment
    Purpose     = "GitHub Actions for application repo"
  }
}

resource "aws_iam_role_policy" "github_actions_app" {
  count = local.enable_github_actions ? 1 : 0

  name = "github-actions-app-policy"
  role = aws_iam_role.github_actions_app[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuthentication"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRImageManagement"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = module.lambda.ecr_repository_arn
      },
      {
        Sid    = "LambdaUpdate"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.lambda_function_name}"
      },
      {
        Sid    = "LambdaInvoke"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.lambda_function_name}"
      }
    ]
  })
}


# ============================================================================
# GitHub Actions Role - Infrastructure Repo (Optional) - Should be done in bootstrap run
# ============================================================================

data "aws_iam_policy_document" "github_actions_infra_assume" {
  count = local.enable_github_actions ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo_infra}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_infra" {
  count = local.enable_github_actions ? 1 : 0

  name               = "${var.project_name}-github-actions-infra"
  assume_role_policy = data.aws_iam_policy_document.github_actions_infra_assume[0].json

  tags = {
    Name        = "${var.project_name}-github-actions-infra"
    Environment = var.environment
    Purpose     = "GitHub Actions for infrastructure repo"
  }
}

resource "aws_iam_role_policy" "github_actions_infra" {
  count = local.enable_github_actions ? 1 : 0

  name = "github-actions-infra-policy"
  role = aws_iam_role.github_actions_infra[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::sano-interview-terraform-state-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::sano-interview-terraform-state-${data.aws_caller_identity.current.account_id}/*"
        ]
      },
      {
        Sid    = "TerraformStateLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/sano-interview-terraform-locks"
      },
      {
        Sid    = "TerraformManagement"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "iam:Get*",
          "iam:List*",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:TagRole",
          "iam:UntagRole",
          "lambda:*",
          "apigateway:*",
          "logs:*",
          "xray:*",
          "cloudwatch:*",
          "ecr:*",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketVersioning",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketTagging",
          "dynamodb:CreateTable",
          "dynamodb:DeleteTable",
          "dynamodb:UpdateTable",
          "dynamodb:TagResource"
        ]
        Resource = "*"
      }
    ]
  })
}