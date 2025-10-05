output "knowledge_base_id" {
  description = "The ID of the knowledge base"
  value       = aws_bedrockagent_knowledge_base.knowledge_base.id
}

output "knowledge_base_arn" {
  description = "The ARN of the knowledge base"
  value       = aws_bedrockagent_knowledge_base.knowledge_base.arn
}

output "knowledge_base_name" {
  description = "The name of the knowledge base"
  value       = aws_bedrockagent_knowledge_base.knowledge_base.name
}

output "opensearch_domain_endpoint" {
  description = "OpenSearch endpoint URL"
  value       = aws_opensearchserverless_collection.knowledge_base_search_collection.collection_endpoint
}

output "data_source_id" {
  description = "The ID of the data source"
  value       = aws_bedrockagent_data_source.data_source.id
}

output "knowledge_base_bucket_name" {
  description = "The name of the S3 bucket for the knowledge base"
  value       = aws_s3_bucket.data_source_bucket.bucket
}

output "knowledge_base_bucket_arn" {
  description = "The ARN of the S3 bucket for the knowledge base"
  value       = aws_s3_bucket.data_source_bucket.arn
}

output "collection_arn" {
  description = "The ARN of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.knowledge_base_search_collection.arn
}

