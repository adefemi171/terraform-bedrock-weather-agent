variable "knowledge_base_name" {
  description = "Name of the knowledge base"
  type        = string
}

variable "knowledge_base_description" {
  description = "Description of the knowledge base"
  type        = string
  default     = "Knowledge Base created with Terraform"
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

