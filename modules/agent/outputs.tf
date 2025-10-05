output "agent_id" {
  description = "The ID of the agent"
  value       = aws_bedrockagent_agent.weather_agent.id
}

output "agent_arn" {
  description = "The ARN of the agent"
  value       = aws_bedrockagent_agent.weather_agent.agent_arn
}

output "agent_name" {
  description = "The name of the agent"
  value       = aws_bedrockagent_agent.weather_agent.agent_name
}

output "agent_alias_id" {
  description = "The ID of the agent alias"
  value       = aws_bedrockagent_agent_alias.agent_alias.id
}

output "agent_alias_arn" {
  description = "The ARN of the agent alias"
  value       = aws_bedrockagent_agent_alias.agent_alias.agent_alias_arn
}

output "agent_alias_name" {
  description = "The name of the agent alias"
  value       = aws_bedrockagent_agent_alias.agent_alias.agent_alias_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.lambda_group_handler.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.lambda_group_handler.function_name
}

