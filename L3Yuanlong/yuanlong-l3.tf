provider "aws" {
    region = "us-east-1"
    shared_credentials_files = ["./LabTerraform/credentials.txt"]    
}

# Create VPC
resource "aws_vpc" "yuanlong-l3" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = { Name = "yuanlong-l3"}
}

# Create IGW
resource "aws_internet_gateway" "igw-l3" {
  vpc_id = aws_vpc.yuanlong-l3.id
  tags = {Name = "igw-l3"}
}

# Route table
resource "aws_route_table" "RT-public" {
  vpc_id = aws_vpc.yuanlong-l3.id
  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-l3.id
  }
  tags = { Name = "RT-public" }
}

# Create public subnet in the VPC
resource "aws_subnet" "SN-public-1" {
  vpc_id     = aws_vpc.yuanlong-l3.id
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {Name = "SN-public-1"}
}

# Create private subnet in the VPC
resource "aws_subnet" "SN-private-1" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "192.168.2.0/24"
  availability_zone = "us-east-1b"
  tags = {Name = "SN-private-1"}
}

# Associate RT and subnet
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.SN-public-1.id
  route_table_id = aws_route_table.RT-public.id
}


# Create a security group allowing SSH and HTTP traffic
resource "aws_security_group" "sg-l3" {
  name = "sg-l3"
  description = "allow HTTP and SSH"
  vpc_id = aws_vpc.yuanlong-l3.id
  ingress = [{
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_block = ["0.0.0.0/0"]
  },{
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_block = ["0.0.0.0/0"]
  }]

}

# Create an EC2 instance in the public subnet
resource "aws_instance" "public_web_server" {
  ami           = "ami-00dfb4bdd9575d36f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.SN-public-1.id
  availability_zone = "us-east-1a"
  security_groups = [aws_security_group.sg-l3.id]
  key_name = "l3"
  tags = {Name = "public_web_server"}
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        cd /var/www/html
        echo "VM $(hostname -f)" > index.html
        systemctl restart httpd
        systemctl enable httpd
        EOF
}

# Create an EC2 instance in the private subnet
resource "aws_instance" "private_web_server" {
  ami           = "ami-00dfb4bdd9575d36f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.SN-private-1.id
  availability_zone = "us-east-1b"
  security_groups = [aws_security_group.sg-l3.id]
  key_name = "l3"
  tags = {Name = "private_web_server"}
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        cd /var/www/html
        echo "VM $(hostname -f)" > index.html
        systemctl restart httpd
        systemctl enable httpd
        EOF
}