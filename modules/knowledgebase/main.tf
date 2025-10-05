data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "data_source_bucket" {
  bucket = "${var.knowledge_base_name}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_source_bucket" {
  bucket = aws_s3_bucket.data_source_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_role" "knowledge_base_role" {
  name = "sc-role-servicerole-${var.knowledge_base_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "knowledge_base_policy" {
  name = "BedrockModelAccess"
  role = aws_iam_role.knowledge_base_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:CreateKnowledgeBase",
          "bedrock:UpdateDataSource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_source_bucket.arn,
          "${aws_s3_bucket.data_source_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "function_role" {
  name = "sc-role-servicerole-function-${var.knowledge_base_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })


  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.function_role.name
}

resource "aws_iam_role_policy" "function_policy" {
  name = "OpenSearchServerlessAccess"
  role = aws_iam_role.function_role.id

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
          "arn:aws:aoss:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:index/*",
          "arn:aws:aoss:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:collection/*"
        ]
      }
    ]
  })
}

resource "aws_opensearchserverless_collection" "knowledge_base_search_collection" {
  name        = var.knowledge_base_name
  description = "An opensearch cluster for the KnowledgeBase"
  type        = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.kb_security_policy,
    aws_opensearchserverless_security_policy.kb_network_policy,
    aws_opensearchserverless_access_policy.kb_data_access_policy
  ]

  tags = var.tags
}

resource "aws_opensearchserverless_security_policy" "kb_security_policy" {
  name        = "kb-security-policy"
  description = "A security policy for the knowledgebase"
  type        = "encryption"

  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource = [
          "collection/${var.knowledge_base_name}"
        ]
      }
    ]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "kb_network_policy" {
  name        = "kb-network-policy"
  description = "Network policy for the knowledgebase"
  type        = "network"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "collection/${var.knowledge_base_name}"
          ]
          ResourceType = "dashboard"
        },
        {
          Resource = [
            "collection/${var.knowledge_base_name}"
          ]
          ResourceType = "collection"
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "kb_data_access_policy" {
  name        = "kb-access-policy"
  description = "Data access policy for the knowledgebase"
  type        = "data"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "index/${var.knowledge_base_name}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ]
          ResourceType = "index"
        },
        {
          Resource = [
            "collection/${var.knowledge_base_name}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
          ResourceType = "collection"
        }
      ]
      Principal = [
        aws_iam_role.knowledge_base_role.arn,
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/sc-ps-standard-admin"
      ]
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "kb_create_index_policy" {
  name        = "kb-create-index-policy"
  description = "Create index policy for the knowledgebase"
  type        = "data"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "index/${var.knowledge_base_name}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ]
          ResourceType = "index"
        },
        {
          Resource = [
            "collection/${var.knowledge_base_name}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
          ResourceType = "collection"
        }
      ]
      Principal = [
        aws_iam_role.function_role.arn
      ]
    }
  ])
}

resource "aws_lambda_layer_version" "opensearch_layer" {
  filename            = "${path.module}/opensearch_layer.zip"
  layer_name          = "opensearch-layer-${var.knowledge_base_name}"
  compatible_runtimes = ["python3.12", "python3.13"]
  description         = "OpenSearch layer for knowledge base"

  depends_on = [data.archive_file.opensearch_layer]
}

data "archive_file" "opensearch_layer" {
  type        = "zip"
  output_path = "${path.module}/opensearch_layer.zip"
  source_dir  = "${path.module}/opensearch_layer"
}

resource "aws_lambda_function" "knowledge_base_index_function" {
  filename      = "${path.module}/functions/oas_index_custom_resource_handler.zip"
  function_name = "knowledge-base-index-${var.knowledge_base_name}"
  role          = aws_iam_role.function_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 120
  description   = "Creates an index in the opensearch collection for the knowledgebase to use"

  layers = [aws_lambda_layer_version.opensearch_layer.arn]

  depends_on = [
    data.archive_file.knowledge_base_index_function,
    aws_opensearchserverless_access_policy.kb_create_index_policy
  ]


  tags = var.tags
}

data "archive_file" "knowledge_base_index_function" {
  type        = "zip"
  output_path = "${path.module}/functions/oas_index_custom_resource_handler.zip"
  source_dir  = "${path.module}/functions/oas_index_custom_resource_handler"
}

resource "terraform_data" "knowledge_base_index_resource" {
  depends_on = [
    aws_opensearchserverless_access_policy.kb_create_index_policy,
    aws_lambda_function.knowledge_base_index_function
  ]

  provisioner "local-exec" {
    command = <<-EOT
      aws lambda invoke \
        --function-name ${aws_lambda_function.knowledge_base_index_function.function_name} \
        --payload '{"RequestType":"Create","ResourceProperties":{"os_url":"${aws_opensearchserverless_collection.knowledge_base_search_collection.collection_endpoint}","index_name":"${var.knowledge_base_name}"}}' \
        --cli-binary-format raw-in-base64-out \
        /tmp/response.json
    EOT
  }

  input = {
    collection_endpoint = aws_opensearchserverless_collection.knowledge_base_search_collection.collection_endpoint
    index_name          = var.knowledge_base_name
  }
}

resource "aws_iam_role_policy_attachment" "opensearch_access" {
  policy_arn = aws_iam_policy.opensearch_serverless_access.arn
  role       = aws_iam_role.knowledge_base_role.name
}

resource "aws_iam_policy" "opensearch_serverless_access" {
  name        = "OpenSearchServerlessAccess"
  description = "Policy for OpenSearch Serverless access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll",
          "aoss:DashboardAccessAll"
        ]
        Resource = aws_opensearchserverless_collection.knowledge_base_search_collection.arn
      }
    ]
  })
}

resource "aws_bedrockagent_knowledge_base" "knowledge_base" {
  name        = var.knowledge_base_name
  description = var.knowledge_base_description
  role_arn    = aws_iam_role.knowledge_base_role.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/amazon.titan-embed-text-v1"
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn = aws_opensearchserverless_collection.knowledge_base_search_collection.arn
      field_mapping {
        metadata_field = "metadata"
        text_field     = "text"
        vector_field   = "vector"
      }
      vector_index_name = var.knowledge_base_name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.opensearch_access,
    aws_opensearchserverless_access_policy.kb_data_access_policy,
    terraform_data.knowledge_base_index_resource
  ]

  tags = var.tags
}

resource "aws_bedrockagent_data_source" "data_source" {
  name                 = var.knowledge_base_name
  knowledge_base_id    = aws_bedrockagent_knowledge_base.knowledge_base.id
  description          = "Source data for the knowledgebase"
  data_deletion_policy = "DELETE"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.data_source_bucket.arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "SEMANTIC"
      semantic_chunking_configuration {
        breakpoint_percentile_threshold = 60
        buffer_size                     = 1
        max_token                       = 1000
      }
    }
  }
}

