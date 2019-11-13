provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

##### VPC Creation - var.cidr_vpc  &   var.environment_tag

resource "aws_vpc" "terraform-vpc" {
  cidr_block = "${var.cidr_vpc}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags  = {
    Environment = "${var.environment_tag}"
  }
}
#### Public Subnet - var.cidr_public_subnet

resource "aws_subnet" "subnet_public" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  cidr_block = "${var.cidr_public_subnet}"
  map_public_ip_on_launch = "true"
  availability_zone = "${var.availability_zone}"
  tags  = {
    Environment = "${var.environment_tag}"
    Action = "Public Subnet Creation"
  }
}


#### Private Subnet - var.cidr_private_subnet

resource "aws_subnet" "subnet_private" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  cidr_block = "${var.cidr_private_subnet}"
  availability_zone = "${var.availability_zone}"
  tags = {
    Environment = "${var.environment_tag}"
    Action = "Private Subnet Creation"
  }
}


##### Create the Internet Gateway
resource "aws_internet_gateway" "terraform-igw" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    Environment = "${var.environment_tag}"
    Action = "IGW Creation"
  }
}



##### Create the EIP & NAT Gateway
resource "aws_eip" "nat" {
    vpc = true
}

resource "aws_nat_gateway" "terraform-NAT" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.subnet_public.id}"
  tags = {
    Environment = "${var.environment_tag}"
    Action = "NAT Creation"
  }
}


##### Create a Custom Route Table
resource "aws_route_table" "custom_rtb_public" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"

##### Create the Routes for Custom RTB

route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.terraform-igw.id}"
}

tags = {
    Environment = "${var.environment_tag}"
    Action = "Custom RTB Creation for Public"
  }
}



#####  Assosiate the Custom RTB with Public Subnet

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = "${aws_subnet.subnet_public.id}"
  route_table_id = "${aws_route_table.custom_rtb_public.id}"
}






##### Create a Custom Route Table for Private
resource "aws_route_table" "custom_rtb_private" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"

##### Create the Routes for Custom RTB

route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_nat_gateway.terraform-NAT.id}"
}

tags = {
    Environment = "${var.environment_tag}"
    Action = "Custom RTB Creation for Private"
  }
}



#####  Assosiate the Custom RTB with Public Subnet

resource "aws_route_table_association" "rta_subnet_private" {
  subnet_id      = "${aws_subnet.subnet_private.id}"
  route_table_id = "${aws_route_table.custom_rtb_private.id}"
}


#####  Create the Webserver SG

resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "webserver sg"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    ### Please restrict your ingress to only necessary IPs and ports.
    ### Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    ### Please restrict your ingress to only necessary IPs and ports.
    ### Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }



  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


##### Creating the Web Server in Public Subnet

resource "aws_instance" "webserver" {
  ami           = "${var.instance_ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${aws_subnet.subnet_public.id}"
  vpc_security_group_ids = ["${aws_security_group.web-sg.id}"]
  key_name = "${var.key_name}"
  user_data = <<-EOF
  #! /bin/bash
      sudo amazon-linux-extras install nginx1 -y
      service nginx start
      EOF
}


#####  Create the Appserver SG

resource "aws_security_group" "app-sg" {
  name        = "app-sg"
  description = "appserver sg"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_public_subnet}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}



##### Creating the App Server in Private Subnet

resource "aws_instance" "appserver" {
  ami           = "${var.instance_ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${aws_subnet.subnet_private.id}"
  vpc_security_group_ids = ["${aws_security_group.app-sg.id}"]
  key_name = "${var.key_name}"
  user_data = <<-EOF
  #! /bin/bash
      sudo yum install tomcat-webapps tomcat-docs-webapp tomcat-admin-webapps -y
      service tomcat start
      EOF
}
