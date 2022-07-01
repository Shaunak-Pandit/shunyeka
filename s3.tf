resource "aws_s3_bucket" "shunyekabucket" {
  bucket = "shaunak-tf-bucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "shunyekaacl" {
  bucket = aws_s3_bucket.shunyekabucket.id
  acl    = "public"
}