variable "project" {
    description = "プロジェクト名"
    type = string
}

variable "environment" {
    description = "環境"
    type = string 
    validation {
        condition = contains(["prod", "stg", "dev"], var.environment)
        error_message = "環境名は'dev', 'stg', 'prod'のいずれかである必要があります"
    }
}

variable "ver" {
    description = "バージョン"
    type = string
}

variable "cidr_block" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "有効なCIDRブロックを指定してください。"
  }
}