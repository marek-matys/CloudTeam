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
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.my-sg-in-from-jh.id]
  subnet_id                   = aws_subnet.SUB_PRIV_0.id
  iam_instance_profile        = aws_iam_instance_profile.my_profile_jh.name

  user_data = <<EOF
#!/bin/bash -xe 
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
yum update -y
cd /home/ec2-user/
aws s3 cp s3://"${var.bucket_name}"/id_rsa_jh.pub .
cat id_rsa_jh.pub  >> ./.ssh/authorized_keys
echo '#!/bin/bash' >> download.sh
echo 'echo "Run date $(date)"' >> download.sh
echo 'cd /home/ec2-user/' >> download.sh
echo 'aws s3 mv s3://"${var.bucket_name}"/in/ ./in/ --include "*.csv" --recursive' >> download.sh
echo 'if [ $? -ne 0 ];then exit; fi' >> download.sh
echo 'for i in $(ls ./in/)' >> download.sh
echo 'do' >> download.sh
echo '        echo "Processing $i"' >> download.sh
echo '        ./processing.sh ./in/$i > ./out/processed-$i' >> download.sh
echo '        if [ $? -ne 0 ];then exit;fi' >> download.sh
echo '        rm ./in/$i' >> download.sh
echo 'done' >> download.sh
echo 'if [ $? -ne 0 ];then exit;fi' >> download.sh
echo 'aws s3 mv ./out/ s3://"${var.bucket_name}"/out/ --include "*.csv" --recursive' >> download.sh
aws s3 cp s3://"${var.bucket_name}"/processing.sh .

chmod 755 ./download.sh
chmod 755 ./processing.sh
chown ec2-user:ec2-user download.sh
chown ec2-user:ec2-user processing.sh
runuser -l ec2-user -c 'mkdir in'
runuser -l ec2-user -c 'mkdir out'

echo "*/1 * * * * sh /home/ec2-user/download.sh >> /home/ec2-user/log.log 2>&1" >> /var/spool/cron/ec2-user
EOF

  depends_on = [aws_main_route_table_association.set-master-default-rt-assoc, aws_iam_role.my_s3_read_role, aws_instance.aws_instance_JH]

}

