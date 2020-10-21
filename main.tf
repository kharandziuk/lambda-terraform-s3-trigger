variable "aws_access_key" {
  description = "Access key to your AWS account "
}

variable "aws_secret_key" {
  description = "Secret key to your AWS account "
}

variable "aws_region" {
  default     = "eu-central-1"
  description = "AWS region"
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "archive_file" "lambda_zip" {
  type          = "zip"
  source_file   = "code/index.js"
  output_path   = local.dist_path
}

locals {
  tmp_path  = "${path.root}/tmp"
  dist_path = "${path.root}/tmp/lambda_function.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename         = local.dist_path
  function_name    = "test_lambda"
  role             = aws_iam_role.iam_for_lambda_tf.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime = "nodejs12.x"
}

resource "aws_iam_role" "iam_for_lambda_tf" {
  name = "iam_for_lambda_tf"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "allow_terraform_bucket" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.arn
  principal = "s3.amazonaws.com"
  source_arn = data.aws_s3_bucket.selected.arn
}

data "aws_s3_bucket" "selected" {
    bucket = "test-bucket-avallone-for-deletion"
}

resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
  bucket = data.aws_s3_bucket.selected.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.test_lambda.arn
    events = ["s3:ObjectRemoved:*"]
  }
}
