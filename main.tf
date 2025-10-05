data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "knowledge_base" {
  source = "./modules/knowledgebase"

  knowledge_base_name        = var.knowledge_base_name
  knowledge_base_description = var.knowledge_base_description
  tags                       = var.tags
}

module "agent" {
  source = "./modules/agent"

  agent_name        = var.agent_name
  agent_instruction = var.agent_instruction
  agent_alias_name  = var.agent_alias_name
  knowledge_base_id = module.knowledge_base.knowledge_base_id
  foundation_model  = var.foundation_model
  tags              = var.tags
}
