# Serverless REST API Infrastructure

Infrastructure as Code for a containerized Python Lambda function exposed via API Gateway REST API, with full observability using OpenTelemetry and AWS X-Ray.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Actions                          │
│  (Terraform PR: lint → validate → plan → comment)              │
│  (Terraform Apply: plan → manual approval → apply)             │
└────────────────────┬────────────────────────────────────────────┘
                     │ OIDC Authentication
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                          AWS Account                            │
│                                                                 │
│  ┌─────────────┐      ┌──────────────────┐                    │
│  │     ECR     │◄─────│ Lambda Function  │                    │
│  │ (Container  │      │   (Container)    │                    │
│  │  Registry)  │      │  - Python 3.11+  │                    │
│  └─────────────┘      │  - OpenTelemetry │                    │
│                       │  - X-Ray Tracing │                    │
│                       └────────┬─────────┘                    │
│                                │                               │
│                                │ Invoked by                    │
│                                │                               │
│                       ┌────────▼─────────┐                    │
│                       │  API Gateway     │                    │
│                       │   REST API       │                    │
│                       │  - CORS enabled  │                    │
│                       │  - CloudWatch    │                    │
│                       │  - X-Ray tracing │                    │
│                       └────────┬─────────┘                    │
│                                │                               │
│                       ┌────────▼─────────┐                    │
│                       │   CloudWatch +   │                    │
│                       │     X-Ray        │                    │
│                       │  - Logs          │                    │
│                       │  - Metrics       │                    │
│                       │  - Traces        │                    │
│                       │  - Alarms        │                    │
│                       │  - Dashboard     │                    │
│                       └──────────────────┘                    │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Terraform State: S3 Bucket + DynamoDB (State Locking)   │ │
│  └──────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- **Containerized Lambda**: Lambda function running in a Docker container for flexible dependencies
- **API Gateway REST API**: Full-featured REST API with throttling, CORS, and custom domains support
- **OpenTelemetry Instrumentation**: Manual SDK instrumentation for detailed tracing
- **AWS X-Ray Integration**: Distributed tracing with AWS X-Ray
- **CloudWatch Monitoring**: Comprehensive logging, metrics, alarms, and dashboards
- **GitHub Actions CI/CD (Optional)**: Automated Terraform workflows with PR validation and manual approval
- **OIDC Authentication (Optional)**: Secure, short-lived credentials for GitHub Actions
- **Remote State**: S3 backend with DynamoDB state locking
- **Reusable Modules**: Lambda container module for code reusability

## Prerequisites

### Core Requirements
- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- AWS account with permissions to create resources
- Docker (for building and pushing container images)

### Optional (for GitHub Actions CI/CD)
- GitHub repository with Actions enabled
- GitHub organization or username for OIDC setup

## Project Structure

```
.
├── .github/workflows/
│   ├── terraform-pr.yml          # PR validation workflow
│   └── terraform-apply.yml       # Apply workflow with manual approval
├── modules/
│   └── lambda-container/         # Reusable Lambda module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── backend.tf                    # S3 backend configuration
├── main.tf                       # Provider and data sources
├── variables.tf                  # Input variables
├── outputs.tf                    # Output values
├── state.tf                      # State backend resources
├── ecr.tf                        # ECR repository
├── iam.tf                        # IAM roles and policies
├── lambda.tf                     # Lambda function
├── api_gateway.tf                # API Gateway configuration
├── monitoring.tf                 # CloudWatch and X-Ray
└── terraform.tfvars.example      # Example variables
```

## Deployment Modes

This infrastructure supports two deployment modes:

### Mode 1: Manual Deployment (No GitHub Required)
- Deploy Lambda, API Gateway, ECR, and monitoring
- Manually build and push Docker images to ECR
- Manually update Lambda function code
- **Best for**: Quick setup, demos, local development

### Mode 2: Full CI/CD with GitHub Actions
- Everything from Mode 1, plus:
- GitHub OIDC provider and IAM roles
- Automated Terraform workflows (PR validation, manual approval)
- Automated application deployments
- **Best for**: Production-like setup, demonstrating DevOps practices

**To enable GitHub Actions**: Set `github_org` in `terraform.tfvars`
**To skip GitHub Actions**: Leave `github_org` empty or commented out

---

## Initial Setup

### 1. Clone and Configure

```bash
git clone <your-repo-url>
cd tf-infra-serverless-rest-api

# Copy example variables and update with your values
cp terraform.tfvars.example terraform.tfvars
```

**For Manual Deployment** (no GitHub Actions), edit `terraform.tfvars`:
```hcl
aws_region           = "us-east-1"
environment          = "dev"
project_name         = "sano-interview"
lambda_function_name = "hello-world-api"
# Leave github_org commented out or empty
```

**For CI/CD with GitHub Actions**, additionally uncomment and set:
```hcl
github_org        = "your-github-username"
github_repo_infra = "tf-infra-serverless-rest-api"
github_repo_app   = "hello-world-app"
```

### 2. Bootstrap Terraform State

The state backend (S3 bucket and DynamoDB table) must be created first with local state:

```bash
# Initialize with local backend
terraform init

# Apply to create state resources
terraform apply -target=aws_s3_bucket.terraform_state \
                -target=aws_dynamodb_table.terraform_locks \
                -target=aws_s3_bucket_versioning.terraform_state \
                -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
                -target=aws_s3_bucket_public_access_block.terraform_state
```

### 3. Migrate to Remote State

After state resources are created:

```bash
# Get your AWS account ID
aws sts get-caller-identity --query Account --output text

# Edit backend.tf:
# 1. Uncomment the backend configuration
# 2. Replace <ACCOUNT_ID> with your AWS account ID

# Migrate state to S3
terraform init -migrate-state

# Confirm the migration when prompted
```

### 4. Deploy Infrastructure

Before deploying the Lambda function, you need to push an initial Docker image to ECR. See the application repo README for instructions, or create a placeholder image:

```bash
# Get ECR repository URL
export ECR_URL=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL

# Build and push a minimal placeholder image
# (This will be replaced by the application CI/CD)
cd ../hello-world-app
docker build -t $ECR_URL:latest .
docker push $ECR_URL:latest
cd ../tf-infra-serverless-rest-api
```

Now deploy the complete infrastructure:

```bash
terraform plan
terraform apply
```

### 5. Configure GitHub Actions (Optional - Only if github_org is set)

**Skip this section if you're doing manual deployment.**

After infrastructure is deployed with GitHub Actions enabled, configure GitHub Actions:

```bash
# Get the outputs
terraform output

# Verify GitHub Actions is enabled
terraform output github_actions_enabled  # Should show: true

# In your GitHub repository, go to Settings > Secrets and variables > Actions
# Add the following repository variables:
# - AWS_GITHUB_ROLE_ARN: <github_oidc_role_arn_infra from output>
# - AWS_REGION: us-east-1 (or your region)
```

Create a GitHub Environment named `production`:
1. Go to Settings > Environments > New environment
2. Name it `production`
3. Add required reviewers (yourself or team members)

## GitHub Actions Workflows (Optional)

> **Note**: This section only applies if you enabled GitHub Actions by setting `github_org` in your terraform.tfvars.

### Pull Request Workflow

Triggered on PRs to `main` that modify Terraform files:
- Runs `terraform fmt -check`
- Runs `terraform validate`
- Runs `terraform plan`
- Posts plan output as PR comment

### Apply Workflow

Triggered on push to `main` that modifies Terraform files:
- Runs `terraform plan`
- **Waits for manual approval** (requires production environment approval)
- Runs `terraform apply`
- Saves outputs as artifacts

---

## Outputs

After deployment, Terraform outputs these values (needed for the application repo):

```bash
terraform output
```

Key outputs:
- `ecr_repository_url`: ECR repository URL for Docker images
- `lambda_function_name`: Lambda function name
- `api_gateway_endpoint`: API Gateway invoke URL
- `github_oidc_role_arn_app`: IAM role ARN for application repo GitHub Actions

## Testing

Test the deployed API:

```bash
# Get API endpoint
export API_ENDPOINT=$(terraform output -raw api_gateway_endpoint)

# Test health endpoint
curl $API_ENDPOINT/prod/health

# Test hello endpoint
curl $API_ENDPOINT/prod/hello
```

View traces in AWS X-Ray console:
```bash
open "https://console.aws.amazon.com/xray/home?region=us-east-1#/service-map"
```

## Cost Considerations

This infrastructure stays within AWS Free Tier limits:
- Lambda: 1M requests/month + 400,000 GB-seconds free
- API Gateway: 1M requests/month free (first 12 months)
- CloudWatch: 10 alarms, 5GB logs free
- X-Ray: 100,000 traces/month free
- ECR: 500MB storage free
- S3: Minimal cost (~$0.01/month)
- DynamoDB: Free tier covers state locking

**Estimated monthly cost: $0-2**

## Interview Discussion Points

### Scaling Considerations
- **API Gateway**: Add usage plans, API keys, request throttling
- **Lambda**: Add provisioned concurrency for consistent performance
- **Multi-region**: Deploy to multiple regions with Route53 for failover
- **Caching**: Add CloudFront CDN and API Gateway caching

### Security Enhancements
- **WAF**: Add AWS WAF for API Gateway protection
- **VPC**: Move Lambda into VPC for private resource access
- **Secrets**: Use AWS Secrets Manager for sensitive configuration
- **Resource Policies**: Add more restrictive resource policies

### Production Readiness
- **Environments**: Separate dev/staging/prod with workspaces or separate state files
- **Approval Process**: Multi-stage approval for production changes
- **Rollback**: Implement blue-green deployments with Lambda aliases
- **Compliance**: Add tagging strategy, AWS Config rules, CloudTrail

### Observability
- **Distributed Tracing**: Custom spans for business logic
- **Metrics**: Custom CloudWatch metrics for business KPIs
- **Log Aggregation**: Ship logs to external service (Datadog, Splunk)
- **Alerting**: PagerDuty/Slack integration for critical alarms

## Troubleshooting

### Terraform Init Fails
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check backend configuration
cat backend.tf
```

### Lambda Deployment Fails
```bash
# Ensure ECR image exists
aws ecr describe-images --repository-name <repo-name> --region us-east-1

# Check Lambda logs
aws logs tail /aws/lambda/<function-name> --follow
```

### GitHub Actions Fails
```bash
# Check OIDC role trust policy
aws iam get-role --role-name <role-name>

# Verify repository variables are set correctly
# Settings > Secrets and variables > Actions
```

## Cleanup

To destroy all resources:

```bash
# Destroy infrastructure
terraform destroy

# Note: S3 bucket with versioning enabled requires manual deletion:
aws s3 rm s3://<bucket-name> --recursive
aws s3api delete-bucket --bucket <bucket-name>
```

## License

This is interview preparation code. Use freely for learning and demonstration purposes.
