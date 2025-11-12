terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }

    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "2.10.1"
    }
  }

  required_version = ">= 1.2"
}