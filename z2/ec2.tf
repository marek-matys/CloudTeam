#Create key-pair for logging into EC2 in us-east-1
resource "aws_key_pair" "master-key" {
  provider   = aws.region-master
  key_name   = "myNewKP"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "aws_instance1" {
  provider                    = aws.region-master
  ami                         = "ami-047a51fa27710816e"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.my-sg.id]
  subnet_id                   = aws_subnet.subnet_1.id
  iam_instance_profile        = aws_iam_instance_profile.my_profile.name

  user_data =<<EOF
#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
yum update -y
amazon-linux-extras install docker
usermod -a -G docker ec2-user
cd /home/ec2-user
aws s3 cp s3://"${var.bucket_name}"/Dockerfile .
aws s3 cp s3://"${var.bucket_name}"/my_logging_server.py .
sudo usermod -a -G docker ec2-user
sudo systemctl start docker
docker build -t hello-world .
docker run -p 8080:8080 hello-world
EOF

  depends_on = [aws_main_route_table_association.set-master-default-rt-assoc, aws_iam_role.my_role]

}

resource "aws_instance" "aws_instance2" {
  provider                    = aws.region-master
  ami                         = "ami-047a51fa27710816e"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.my-sg.id]
  subnet_id                   = aws_subnet.subnet_2.id
  iam_instance_profile        = aws_iam_instance_profile.my_profile.name

  user_data =<<EOF
#!/bin/bash -xe 
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
yum update -y
amazon-linux-extras install docker
usermod -a -G docker ec2-user
cd /home/ec2-user
aws s3 cp s3://"${var.bucket_name}"/Dockerfile .
aws s3 cp s3://"${var.bucket_name}"/my_logging_server.py .
sudo usermod -a -G docker ec2-user
sudo systemctl start docker
docker build -t hello-world .
docker run -p 8080:8080 hello-world
EOF

  depends_on = [aws_main_route_table_association.set-master-default-rt-assoc, aws_iam_role.my_role]

}
