#ad an object
resource "aws_s3_bucket_object" "object1" {
  provider = aws.region-master
  bucket   = var.bucket_name

  acl = "private" # or can be "public-read"

  key = "processing.sh"

  source = "${path.module}/processing.sh"


}



