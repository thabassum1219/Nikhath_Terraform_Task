resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "main"
  }
}
###############Creating a Internet Gateway############
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "IGW"
  }
}
################## Creating a Route Table #######################
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "route_table"
  }
}
####################### Creating a Subnet ##################
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  #map_public_ip_on_launch=true
  tags = {
    Name = "Public-Subnet"
  }
}
################### Association Of Subnet With Route Table ####################
resource "aws_route_table_association" "association" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}
####################### Security Group #########################
resource "aws_security_group" "allow_ssh_http_https" {
  name        = "SG"
  description = "Security group to allow SSH, HTTP, and HTTPS traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh_http_https"
  }
}
######################## Creating a Network Interface #################
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.main.id
  security_groups = [aws_security_group.allow_ssh_http_https.id]
  attachment {
    instance     = aws_instance.test.id
    device_index = 1
  }
  tags = {
    Name = "Test-Network-Interface"
  }
}
##################### Allocating Elastic IP to NI##############
resource "aws_eip" "test" {
  #instance = aws_instance.test.id
  vpc      = true
}
# Associate the Elastic IP with the Network Interface
resource "aws_eip_association" "test" {
  # network_interface_id = aws_network_interface.test.id
  instance_id   = aws_instance.test.id
  allocation_id = aws_eip.test.id
}
#################### Creating an EC2 ##########################
resource "aws_instance" "test" {
  ami           = "ami-04b70fa74e45c3917" # Replace with your desired AMI
  instance_type = "t2.micro"
  key_name      = "forkey"
  subnet_id     = aws_subnet.main.id
  #####key_name = ""
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http_https.id]
  associate_public_ip_address = false # Enable auto-assigning public IP
  user_data                   = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "first Webserver httpd" > /var/www/html/index.html
              EOF
  tags = {
    Name = "Test-Instance"
  }
}
resource "aws_s3_bucket" "s3_bucket" {
bucket = "s3backend1219123456"
acl = "private"
}
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
name = "terraform-state-lock-dynamo"
hash_key = "LockID"
read_capacity = 20
write_capacity = 20
attribute {
name = "LockID"
type = "S"
}
}
terraform {
  backend "s3" {
    bucket = "s3backend1219123456"
    dynamodb_table = "terraform-state-lock-dynamo"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
