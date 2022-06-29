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

data "archive_file" "zip_the_python_code" {
type        = "zip"
source_dir  = "${path.module}/python/"
output_path = "${path.module}/python/hello-python.zip"
}

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = "${path.module}/python/hello-python.zip"
  function_name = "lambda_function_name"
  role          = aws_iam_role.cloudformation_s3_lambda_role.arn
  handler       = "index.test"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("hello-python.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}
