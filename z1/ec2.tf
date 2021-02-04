#Create key-pair for logging into EC2 in us-east-1
resource "aws_key_pair" "master-key" {
  provider   = aws.region-master
  key_name   = "myNewKP"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "aws_instance_JH" {
  provider                    = aws.region-master
  ami                         = "ami-047a51fa27710816e"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.my-sg-out-to-jh.id]
  subnet_id                   = aws_subnet.SUB_DMZ_0.id
  iam_instance_profile        = aws_iam_instance_profile.my_profile_jh.name

  user_data = <<EOF
#!/bin/bash -xe 
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
yum update -y
cd /home/ec2-user/
runuser ec2-user -c 'ssh-keygen -t rsa -f ./.ssh/id_rsa -q -N ""'
#chown ec2-user:ec2-user ./.ssh/id_rsa
#chown ec2-user:ec2-user ./.ssh/id_rsa.pub
aws s3 cp ./.ssh/id_rsa.pub s3://"${var.bucket_name}"/id_rsa_jh.pub
EOF

  depends_on = [aws_main_route_table_association.set-master-default-rt-assoc, aws_iam_role.my_s3_full_role]

}

resource "aws_instance" "aws_instance_dev1" {
  provider                    = aws.region-master
  ami                         = "ami-047a51fa27710816e"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.my-sg-in-from-jh.id]
  subnet_id                   = aws_subnet.SUB_PRIV_0.id
  iam_instance_profile        = aws_iam_instance_profile.my_profile_dev.name

  user_data = <<EOF
#!/bin/bash -xe 
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
yum update -y
cd /home/ec2-user/
aws s3 cp s3://"${var.bucket_name}"/id_rsa_jh.pub .
cat id_rsa_jh.pub  >> ./.ssh/authorized_keys
EOF

  depends_on = [aws_main_route_table_association.set-master-default-rt-assoc, aws_iam_role.my_s3_read_role, aws_instance.aws_instance_JH]

}

resource "aws_instance" "aws_instance_dev2" {
  provider                    = aws.region-master
  ami                         = "ami-047a51fa27710816e"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.my-sg-in-from-jh.id]
  subnet_id                   = aws_subnet.SUB_PRIV_1.id
  iam_instance_profile        = aws_iam_instance_profile.my_profile_dev.name

  user_data = <<EOF
#!/bin/bash -xe 
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
yum update -y
cd /home/ec2-user/
aws s3 cp s3://"${var.bucket_name}"/id_rsa_jh.pub .
cat id_rsa_jh.pub  >> ./.ssh/authorized_keys
EOF

  depends_on = [aws_main_route_table_association.set-master-default-rt-assoc, aws_iam_role.my_s3_read_role, aws_instance.aws_instance_JH]

}
