#ad an object
resource "aws_s3_bucket_object" "object1" {
  provider = aws.region-master
  bucket = var.bucket_name

  acl    = "private"  # or can be "public-read"

  key = "Dockerfile"

  source = "${path.module}/Dockerfile"

  
}

resource "aws_s3_bucket_object" "object2" {
  provider = aws.region-master
  bucket = var.bucket_name

  acl    = "private"  # or can be "public-read"
  key = "my_logging_server.py"

  source = "${path.module}/my_logging_server.py"                                                                                                                                   
}
