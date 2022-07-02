terraform {
  backend "s3" {
    bucket = "my-s3-bucket"
    key    = "path/to/my/key"
    region = "ap-south-1"
    access_key = "AKIA3WIQTEQNEMYFXI6J"
    secret_key = "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"
  }
}
provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "my-s3-bucket" {
  bucket_prefix = var.bucket_prefix
  acl = var.acl
  
   versioning {
    enabled = var.versioning
  }
  
  tags = var.tags
}

resource "aws_s3_bucket_object" "function" {
  bucket = module.my-s3-bucket.id
  key    = "hello-python.zip"
  source = data.archive_file.terraform_lambda_func.output_path
}

resource "aws_iam_role" "lambda_role" {
  name = "terraform_aws_lambda_role"

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

resource "aws_iam_policy" "iam_policy_for_lambda"{
    name        = "aws_iam_policy_for_terraform_aws_lambda_role"
    path        ="/"
    description = "Policy to manage lambda role"
    policy= <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "s3:*"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },###
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::my-s3-bucket"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": "arn:aws:s3:::my-s3-bucket/path/to/my/key"
    } ###
  ]
}
EOF  
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
    role        = aws_iam_role.lambda_role.name
    policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn  
} 

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_file = "${path.module}/python/"
  output_path = "${path.module}/python/hello-python.zip"
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename         = "${path.module}/python/hello-python.zip"
  function_name    = "shunyeka-function"
  role             = aws_iam_role.lambda_role.arn 
  handler          = "hello-python.lambda_handler"
  runtime          = "python3.8"
  depends_on       = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role] 
  environment {
    variables = {
      s3_bucket = aws_s3_bucket_object.function.bucket
      s3_key    = aws_s3_bucket_object.function.key
    }
  }
}

output "terraform_aws_role_output"{
    value = aws_iam_role.lambda_role.name
}



