variable "agent_name" {
  description = "Name of the agent"
  type        = string
}

variable "agent_instruction" {
  description = "Instructions for the agent"
  type        = string
  default     = "You are a helpful clothing advisor that suggests what to wear based on weather conditions. When users ask about what to wear, always ask for their location if they haven't provided it. Provide detailed clothing suggestions based on temperature, precipitation, wind, and other weather factors. Be friendly and conversational in your responses. Always consider the latest weather data and trends to provide accurate suggestions."
}

variable "agent_alias_name" {
  description = "Name of the agent alias"
  type        = string
  default     = "weather-agent-alias"
}

variable "knowledge_base_id" {
  description = "ID of the knowledge base to associate with the agent"
  type        = string
}

variable "foundation_model" {
  description = "Name of the foundation model"
  type        = string
  default     = "anthropic.claude-3-5-sonnet-20240620-v1:0"
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

