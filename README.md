# AWS Bedrock Agent with Terraform

This Terraform configuration creates a Knowledge Base and an Agent that provides weather clothing suggestions based on user queries.

## Architecture

The infrastructure consists of:

1. **Knowledge Base Module** (`modules/knowledgebase/`)
   - S3 bucket for data storage
   - OpenSearch Serverless collection
   - Bedrock Knowledge Base
   - Lambda function for index management
   - IAM roles and policies

2. **Agent Module** (`modules/agent/`)
   - Bedrock Agent with weather clothing suggestions
   - Lambda function for weather API integration
   - Agent alias for deployment
   - IAM roles and policies

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions

## Quick Start

1. **Clone and navigate to the terraform directory:**

   ```bash
   cd terraform
   ```

2. **Copy and customize variables:**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform:**

   ```bash
   terraform init
   ```

4. **Plan the deployment:**

   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure:**

   ```bash
   terraform apply
   ```

## Configuration

### Required Variables

- `knowledge_base_name`: Name for the Bedrock Knowledge Base
- `agent_name`: Name for the Bedrock Agent

### Optional Variables

- `aws_region`: AWS region (default: us-east-1)
- `agent_instruction`: Custom instructions for the agent
- `foundation_model`: Bedrock foundation model to use
- `tags`: Resource tags

## Modules

### Knowledge Base Module

Creates a complete Bedrock Knowledge Base with:

- S3 bucket for document storage
- OpenSearch Serverless for vector search
- Lambda function for index management
- Proper IAM roles and policies

### Agent Module

Creates a Bedrock Agent with:

- Weather API integration via Lambda
- Knowledge Base association
- Agent alias for deployment
- Comprehensive IAM permissions

## Outputs

After deployment, Terraform provides:

- Knowledge Base ID and ARN
- Agent ID and ARN
- Agent Alias ID and ARN
- Lambda function details

## Cleanup

To destroy all resources:

```bash
terraform destroy
```
