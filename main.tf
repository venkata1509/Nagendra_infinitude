# main.tf

provider "aws" {
  region = "eu-north-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = "vpc-09cca262899d5286d"

  tags = {
    Name = "main-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = "vpc-09cca262899d5286d"
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.eu-north-1b}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = "vpc-09cca262899d5286d"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = "subnet-01296ac79f4c781df"
  route_table_id = "rtb-0bd59f4f362bbc365"
}

# Security Group
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami           = "ami-000defd1c33d4d17b"
  instance_type = "t3.micro"
  subnet_id     = "subnet-01296ac79f4c781df"

  vpc_security_group_ids = [aws_security_group.allow_http.id]

  tags = {
    Name = "AppServer"
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name        = "main-api"
  description = "Main API Gateway"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = "ANY"

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_instance.app_server.public_ip}"
}

resource "aws_api_gateway_deployment" "main" {
  depends_on = [aws_api_gateway_integration.proxy]

  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = "prod"
}

# Output
output "api_gateway_url" {
  value = aws_api_gateway_deployment.main.invoke_url
}

output "ec2_public_ip" {
  value = "16.171.173.229"
}