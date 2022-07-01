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

resource "aws_iam_policy" "iam_policy" {
  name = "lambda_access-policy"
  description = "IAM Policy"
policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.bucket_prefix}",
                "arn:aws:s3:::${var.bucket_prefix}/*"
            ]
        },
        {
          "Action": [
            "autoscaling:Describe*",
            "cloudwatch:*",
            "logs:*",
            "sns:*"
          ],
          "Effect": "Allow",
          "Resource": "*"
        }
  ]
}
  EOF
}

resource "aws_iam_role" "role" {
  name = "${var.role_name}-role"
  path = "/"
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
resource "aws_iam_role_policy_attachment" "iam-policy-attach" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.iam_policy.arn}"
}

locals{
  lambda_zip_location = "outputs/welcome.zip"
}

data "archive_file" "welcome" {
  type        = "zip"
  source_file = "welcome.py"
  output_path = "${local.lambda_zip_location}"
}

resource "aws_lambda_function" "test_lambda" {
  filename         = "${local.lambda_zip_location}"
  role             = "${aws_iam_role.role.arn}"
  function_name    = "welcome"
  handler          = "welcome.hello"
  runtime          = "python3.7"
  timeout          = 180
}

