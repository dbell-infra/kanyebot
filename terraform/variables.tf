variable "aws_account_id" {
  type    = string
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "bucket_prefix" {
  type = string
}

variable "webhook_function" {
  type    = string
  default = "kanyebot-webhook"
}

variable "webhook_token" {
  type = string
}

variable "chatbot_name" {
  type = string
  default = "KanyeBot"
}

