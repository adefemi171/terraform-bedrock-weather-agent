output "knowledge_base_name" {
  description = "The name of the knowledge base"
  value       = module.knowledge_base.knowledge_base_name
}

output "knowledge_base_id" {
  description = "The ID of the knowledge base"
  value       = module.knowledge_base.knowledge_base_id
}

output "knowledge_base_arn" {
  description = "The ARN of the knowledge base"
  value       = module.knowledge_base.knowledge_base_arn
}

output "knowledge_base_bucket_name" {
  description = "The name of the S3 bucket for the knowledge base"
  value       = module.knowledge_base.knowledge_base_bucket_name
}

output "opensearch_domain_endpoint" {
  description = "OpenSearch endpoint URL"
  value       = module.knowledge_base.opensearch_domain_endpoint
}

output "agent_name" {
  description = "The name of the agent"
  value       = module.agent.agent_name
}

output "agent_id" {
  description = "The ID of the agent"
  value       = module.agent.agent_id
}

output "agent_arn" {
  description = "The ARN of the agent"
  value       = module.agent.agent_arn
}

output "agent_alias_name" {
  description = "The name of the agent alias"
  value       = module.agent.agent_alias_name
}

output "agent_alias_id" {
  description = "The ID of the agent alias"
  value       = module.agent.agent_alias_id
}

output "agent_alias_arn" {
  description = "The ARN of the agent alias"
  value       = module.agent.agent_alias_arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = module.agent.lambda_function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = module.agent.lambda_function_arn
}

