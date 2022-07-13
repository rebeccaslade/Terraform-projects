provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "apache-server" {
  cidr_block = "10.0.0.0/16"
tags = {
    Name = "apache-server"
  }
}
resource "aws_internet_gateway" "apache-server-igw" {
  vpc_id = aws_vpc.apache-server.id

  tags = {
    Name = "apache-server-igw"
  }
}
  resource "aws_route_table" "apache-server-route-table" {
  vpc_id = aws_vpc.apache-server.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.apache-server-igw.id

  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.apache-server-igw.id
  }

  tags = {
    Name = "apache-server-route-table"
  }
  }
resource "aws_subnet" "subnet-a" {
  vpc_id     = aws_vpc.apache-server.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-a"
  }

}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-a.id
  route_table_id = aws_route_table.apache-server-route-table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.apache-server.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web-traffic"
  }
}

resource "aws_network_interface" "apache-server-nic" {
  subnet_id       = aws_subnet.subnet-a.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.apache-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.apache-server-igw]
}

resource "aws_instance" "apache-server-instance" {
  ami = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.apache-server-nic.id
  }

user_data = <<-EOF
#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo bash -c 'echo your very first web server > /var/www/html/index.html'
EOF

tags = {
  Name = "apache-web-server"
}

}





