
# Provider AWS
provider "aws" {
  region     = "us-east-1"
}

# Create vpc 
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    
    tags = {
    Name = "cust_vpc"
  }
}

# Create Public Subnet
 resource "aws_subnet" "pub_sub" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub_subnet"
  }
}

# Create Private Subnet
 resource "aws_subnet" "pri_sub" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  
    tags = {
    Name = "pri_subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "net_igw"
  }
}

#Create Elastic IP
resource "aws_eip" "eip" {
  
}

#Create NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pub_sub.id

  tags = {
    Name = "nat_gw"
  }
}
# Create Route Table For Public Subnet
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route_pub"
  }
}

# Create Route Table for Private Subnet
resource "aws_route_table" "route1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "route_pri"
  }
}

#Subnet Association For Public Subnet
resource "aws_route_table_association" "pub_ass" {
  subnet_id      = aws_subnet.pub_sub.id
  route_table_id = aws_route_table.route.id
}

#Subnet Association For Private Subnet
resource "aws_route_table_association" "pri_ass" {
  subnet_id      = aws_subnet.pri_sub.id
  route_table_id = aws_route_table.route1.id
}

# Create Security Group for Public Subnet
resource "aws_security_group" "pubsg" {
  name   = "pub_sg"
  vpc_id = aws_vpc.vpc.id

  # Inbound Rule
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Group for Private Subnet
resource "aws_security_group" "prisg" {
  name   = "pri_sg"
  vpc_id = aws_vpc.vpc.id

  # Inbound Rule
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  # Outbound Rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_pub" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pub_sub.id
  vpc_security_group_ids = [aws_security_group.pubsg.id]
  key_name   = "aws_key"

  tags = {
    Name = "pub_insta"
  }
}

resource "aws_instance" "ec2_pri" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pri_sub.id
  vpc_security_group_ids = [aws_security_group.prisg.id]
  key_name   = "aws_key"

  tags = {
    Name = "pri_insta"
  }
}


# RSA key 
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create aws Key Pair 
resource "aws_key_pair" "key" {
  key_name   = "aws_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "TF_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tfkey"
}