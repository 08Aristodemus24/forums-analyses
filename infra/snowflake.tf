

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
    "snowflake_storage_integration_resource"
  ]
}

# databases
resource "snowflake_database" "forums_analyses_db" {
  name         = "FORUMS_ANALYSES_DB"
  is_transient = false
}

# schemas
resource "snowflake_schema" "forums_analyses_bronze" {
  name         = "FORUMS_ANALYSES_BRONZE"
  database     = snowflake_database.forums_analyses_db.name
  is_transient = false
}

# external volume
resource "snowflake_external_volume" "forums_analyses_ext_vol" {
  name = "forums_analyses_ext_vol"
  storage_location {
    storage_location_name = "delta-ap-southeast-2"
    storage_base_url      = "s3://${aws_s3_bucket.forums_analyses_bucket.bucket}/"
    storage_provider      = "S3"
    storage_aws_role_arn  = aws_iam_role.forum_analyses_ext_int_role.arn
  }
  allow_writes = true

  # this strictly must be created only after creating 
  # the IAM role, policy, attaching the policy to that 
  # role
  depends_on = [
    aws_iam_role_policy_attachment.faei_role_policy_attachment
  ]
}

# storage integration
resource "snowflake_storage_integration" "forums_analyses_si" {
  name                      = "forums_analyses_si"
  type                      = "EXTERNAL_STAGE"
  storage_provider          = "S3"
  enabled                   = true
  storage_aws_role_arn      = aws_iam_role.forum_analyses_ext_int_role.arn
  storage_allowed_locations = ["s3://${aws_s3_bucket.forums_analyses_bucket.bucket}"]

  # this strictly must be created only after creating 
  # the IAM role, policy, attaching the policy to that 
  # role
  depends_on = [
    aws_iam_role_policy_attachment.faei_role_policy_attachment
  ]
}

# this allows our current accountadmin role to have the privilege
# like we do in the snowflake UI to read, list, update, delete,
# etc. objects at the level of the platform itself, meaning
# creating a data warehouse compute instance, etc. This allows
# us to ultimately have access to the external volumes, schemas,
# databases, we create using terraform, when originally we didn't

# database privileges
resource "snowflake_grant_privileges_to_account_role" "fa_database_allowed_roles" {
  account_role_name = var.snowflake_role
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.forums_analyses_db.name
  }
  always_apply      = true
  all_privileges    = true
  with_grant_option = true
}

# schema privileges
resource "snowflake_grant_privileges_to_account_role" "fa_schema_allowed_roles" {
  account_role_name = var.snowflake_role
  on_schema {
    schema_name = snowflake_schema.forums_analyses_bronze.fully_qualified_name
  }
  always_apply      = true
  all_privileges    = true
  with_grant_option = true
}

# external volume privileges
resource "snowflake_grant_privileges_to_account_role" "fa_ext_vol_allowed_roles" {
  account_role_name = var.snowflake_role
  on_account_object {
    object_type = "EXTERNAL VOLUME"
    object_name = snowflake_external_volume.forums_analyses_ext_vol.name
  }
  always_apply      = true
  all_privileges    = true
  with_grant_option = true
}

# storage integration privileges
resource "snowflake_grant_privileges_to_account_role" "fa_si_allowed_roles" {
  account_role_name = var.snowflake_role
  on_account_object {
    object_type = "INTEGRATION"
    object_name = snowflake_storage_integration.forums_analyses_si.name
  }
  always_apply      = true
  all_privileges    = true
  with_grant_option = true
}

