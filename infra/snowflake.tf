

provider "snowflake" {
  organization_name      = var.snowflake_org_name
  account_name           = var.snowflake_account_name
  user                   = var.snowflake_login_name // e.g., "TERRAFORM_SVC"  
  role                   = var.snowflake_role       // Default role for the provider's operations  
  authenticator          = "SNOWFLAKE_JWT"
  private_key            = var.private_key
  private_key_passphrase = var.private_key_passphrase

  # this is imperative to add in order to create
  # snowflake_external_volume_resource
  preview_features_enabled = [
    "snowflake_external_volume_resource",
  ]
}

#######################################
# Databases
#######################################

resource "snowflake_database" "forums_analyses_db" {
  name         = "FORUMS_ANALYSES_DB"
  is_transient = false
}

#######################################
# Schemas
#######################################

resource "snowflake_schema" "forums_analyses_bronze" {
  name         = "FORUMS_ANALYSES_BRONZE"
  database     = snowflake_database.forums_analyses_db.name
  is_transient = false
}

resource "snowflake_external_volume" "forums_analyses_ext_vol" {
  
  name = "forums_analyses_ext_vol"
  storage_location {
    storage_location_name = "delta-ap-southeast-2"
    storage_base_url      = "s3://${aws_s3_bucket.forums_analyses_bucket.bucket}/"
    storage_provider      = "S3"
    storage_aws_role_arn  = aws_iam_role.forum_analyses_ext_int_role.arn
  }
  allow_writes = false
  depends_on = [
    aws_iam_role_policy_attachment.faei_role_policy_attachment
  ]
}

