#Grants permissions to assume the role
resource "aws_iam_role" "my_s3_full_role" {
  provider = aws.region-master
  name     = "my_s3_full_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "my_profile_jh" {
  provider = aws.region-master
  name     = "my_profile_jh"
  role     = aws_iam_role.my_s3_full_role.name
}

#Permisssions here
resource "aws_iam_role_policy" "my_S3_full_policy" {
  provider = aws.region-master
  name     = "my_S3_FullAccess"
  role     = aws_iam_role.my_s3_full_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [        
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}



#Grants permissions to assume the role
resource "aws_iam_role" "my_s3_read_role" {
  provider = aws.region-master
  name     = "my_s3_read_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "my_profile_dev" {
  provider = aws.region-master
  name     = "my_profile_dev"
  role     = aws_iam_role.my_s3_read_role.name
}

#Permisssions here
resource "aws_iam_role_policy" "my_S3_read_policy" {
  provider = aws.region-master
  name     = "my_S3_ReadAccess"
  role     = aws_iam_role.my_s3_read_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [        
        {
            "Effect": "Allow",
            "Action": [
		"s3:Get*",
		"s3:List*"
	    ],
            "Resource": "*"
        }
    ]
}
EOF
}
