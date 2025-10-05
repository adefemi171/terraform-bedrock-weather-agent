data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_lambda_layer_version" "powertools_layer" {
  filename            = "${path.module}/powertools_layer.zip"
  layer_name          = "powertools-layer-${var.agent_name}"
  compatible_runtimes = ["python3.12", "python3.13"]
  description         = "AWS Lambda Powertools layer"

  depends_on = [data.archive_file.powertools_layer]
}

data "archive_file" "powertools_layer" {
  type        = "zip"
  output_path = "${path.module}/powertools_layer.zip"
  source_dir  = "${path.module}/powertools_layer"
}

resource "aws_iam_role" "agent_functions_role" {
  name = "sc-role-servicerole-AgentFunctionRole-${var.agent_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.agent_functions_role.name
}

resource "aws_iam_role_policy" "agent_functions_policy" {
  name = "AmazonBedrockAgentQuickCreateLambdaPolicy"
  role = aws_iam_role.agent_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.lambda_group_handler.function_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTelemetryRecords",
          "xray:PutTraceSegments"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "lambda_group_handler" {
  filename      = "${path.module}/functions/weather_agent.zip"
  function_name = "weather-agent-${var.agent_name}"
  role          = aws_iam_role.agent_functions_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.13"
  timeout       = 60
  memory_size   = 128
  description   = "Weather agent Lambda function for Bedrock"

  layers = [aws_lambda_layer_version.powertools_layer.arn]

  depends_on = [data.archive_file.weather_agent_function]

  environment {
    variables = {
      POWERTOOLS_METRICS_NAMESPACE = "bedrock-agent-${var.agent_name}"
      POWERTOOLS_SERVICE_NAME      = "bedrock-agent-${var.agent_name}"
    }
  }

  tags = var.tags
}

data "archive_file" "weather_agent_function" {
  type        = "zip"
  output_path = "${path.module}/functions/weather_agent.zip"
  source_dir  = "${path.module}/functions/weather_agent"
}

resource "aws_lambda_permission" "agent_functions_for_lambda_role_bedrock" {
  statement_id   = "AllowExecutionFromBedrock"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.lambda_group_handler.function_name
  principal      = "bedrock.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn     = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agent/*"
}

resource "aws_iam_role" "amazon_bedrock_execution_role_for_agents" {
  name = "sc-role-servicerole-${var.agent_name}-ExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agent/*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "bedrock_model_access" {
  name = "BedrockModelAccess"
  role = aws_iam_role.amazon_bedrock_execution_role_for_agents.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:List*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:GetAgentVersion",
          "bedrock:GetAgentAlias",
          "bedrock:GetAgentMemory",
          "bedrock:GetAgent",
          "bedrock:GetAgentActionGroup",
          "bedrock:GetAgentKnowledgeBase",
          "bedrock:ListAgentVersions",
          "bedrock:InvokeAgent",
          "bedrock:ListAgentActionGroups",
          "bedrock:ListAgentKnowledgeBases",
          "bedrock:ListAgentAliases"
        ]
        Resource = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agent/${var.agent_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:GetKnowledgeBase",
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/${var.knowledge_base_id}"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/${var.foundation_model}"
      }
    ]
  })
}

resource "aws_iam_role_policy" "opensearch_serverless_access" {
  name = "OpenSearchServerlessAccess"
  role = aws_iam_role.amazon_bedrock_execution_role_for_agents.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll",
          "aoss:DashboardAccessAll"
        ]
        Resource = [
          "arn:aws:aoss:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:collection/${var.knowledge_base_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "aoss:CreateIndex",
          "aoss:DeleteIndex",
          "aoss:UpdateIndex",
          "aoss:DescribeIndex",
          "aoss:ReadDocument",
          "aoss:WriteDocument"
        ]
        Resource = [
          "arn:aws:aoss:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      }
    ]
  })
}

resource "aws_bedrockagent_agent" "weather_agent" {
  agent_name                  = var.agent_name
  agent_resource_role_arn     = aws_iam_role.amazon_bedrock_execution_role_for_agents.arn
  description                 = "An agent that suggests clothing based on weather conditions"
  idle_session_ttl_in_seconds = 600
  instruction                 = var.agent_instruction
  foundation_model            = var.foundation_model

  tags = var.tags
}

resource "aws_bedrockagent_agent_alias" "agent_alias" {
  agent_alias_name = var.agent_alias_name
  agent_id         = aws_bedrockagent_agent.weather_agent.agent_id
  description      = "Weather agent alias created using Terraform"

  tags = var.tags
}
