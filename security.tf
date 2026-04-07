# Security and Compliance
# CloudTrail audit logging and security configurations
#
# NOTE: In a production environment, CloudTrail would typically be managed in a
# separate "foundation" or "security" Terraform repository owned by the security
# or platform team, often at the AWS Organization level to cover all accounts.
# It's included here for demonstration purposes and to show security awareness.

# ============================================================================
# CloudTrail Audit Logging
# ============================================================================

# S3 bucket for CloudTrail audit logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.project_name}-cloudtrail-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name       = "${var.project_name}-cloudtrail-logs"
    Purpose    = "Audit logging for compliance"
    Compliance = "SOC2"
    DataClass  = "audit"
  }
}

# Enable versioning for audit log immutability
resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt audit logs at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to audit logs
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for audit log retention
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "audit-log-retention"
    status = "Enabled"

    # Transition to Glacier after 90 days (cost optimization)
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete after 365 days (adjust based on compliance requirements)
    # For SOC2/HIPAA, you might need 7 years (2555 days)
    expiration {
      days = 365
    }
  }
}

# S3 bucket policy to allow CloudTrail to write logs
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudTrail for audit logging
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  # Log all management events (API calls)
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # Optionally log data events (S3 object-level, Lambda invocations)
    # Disabled by default to control costs
    # data_resource {
    #   type   = "AWS::S3::Object"
    #   values = ["arn:aws:s3:::"]
    # }
  }

  tags = {
    Name       = "${var.project_name}-audit-trail"
    Purpose    = "Audit logging for compliance"
    Compliance = "SOC2"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}
