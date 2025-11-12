provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_s3_bucket" "forums_analyses_bucket" {
  bucket = "${var.project_name}-bucket"

  tags = {
    Name        = "${var.project_name}-bucket"
    Environment = "Dev"
  }

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.forums_analyses_bucket.id

  # Block public access to buckets and objects granted through new access control lists (ACLs)
  # When set to true causes the following behavior:
  # PUT Bucket ACL and PUT Object ACL calls will fail if the specified ACL allows public access.
  # PUT Object calls will fail if the request includes an object ACL.
  block_public_acls = false

  # Block public access to buckets and objects granted through new public bucket or access point policies
  # When set to true causes Amazon S3 to:
  # Reject calls to PUT Bucket policy if the specified bucket policy allows public access.
  block_public_policy = false

  # Block public access to buckets and objects granted through any access control lists (ACLs)
  ignore_public_acls = true

  # Block public and cross-account access to buckets and objects through any public bucket or access point policies
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "forums_analyses_bucket_access_policy" {
  bucket = aws_s3_bucket.forums_analyses_bucket.id

  # we need to have this access policy be jsonified otherwise
  # it will throw a ` Inappropriate value for attribute "policy": string required.`
  policy = data.aws_iam_policy_document.forums_analyses_bucket_access_policy.json
}

data "aws_iam_policy_document" "forums_analyses_bucket_access_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.forums_analyses_bucket.arn,
      "${aws_s3_bucket.forums_analyses_bucket.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "forum_analyses_ext_int_policy" {
  name        = "forums_analyses_ext_int_policy"
  description = "a policy that will be attached to an IAM role used for accessing snowflake"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Statement1",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::forums-analyses-bucket",
          "arn:aws:s3:::forums-analyses-bucket/*"
        ]
      }
    ]
  })

  # this ensures that the iam policy is ran strictly
  # only after the bucket has been created
  depends_on = [
    aws_s3_bucket.forums_analyses_bucket
  ]
}

data "aws_caller_identity" "current" {}

# we create a role which we will
resource "aws_iam_role" "forum_analyses_ext_int_role" {
  name = "forums_analyses_ext_int_role"

  # this is actually the trusted entities section
  # of a role that we know we must initially fill values
  # with and later replace manually from the output of
  # the snowflake external volume and stage integrations
  
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Principal" = {
          "AWS" = data.aws_caller_identity.current.id
        },
        "Action" = "sts:AssumeRole",
        "Condition" = {
          "StringEquals" = {
            "sts:ExternalId" = [
              "xxxxxxxx",
            ]
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.forums_analyses_bucket
  ]
}


# this is where we explicitly attach the policy we 
# created for the role we just created
resource "aws_iam_role_policy_attachment" "faei_role_policy_attachment" {
  role       = aws_iam_role.forum_analyses_ext_int_role.name
  policy_arn = aws_iam_policy.forum_analyses_ext_int_policy.arn

  depends_on = [
    aws_iam_role.forum_analyses_ext_int_role,
    aws_iam_policy.forum_analyses_ext_int_policy
  ]
}

# once our IAM role and policy is created we will
# need to normally copy the arn of the IAM role 
# to attach it to our snowflake storage integration 
# but in this case we will output it to terraform so
# that it can be accessed by other terraform files
# case on our snowflake.tf file which will create our
# external volumes and integrations
output "forums_analyses_ext_int_role_arn" {
  value = aws_iam_role.forum_analyses_ext_int_role.arn
}

output "forums_analyses_bucket_name" {
  value = aws_s3_bucket.forums_analyses_bucket.bucket
}