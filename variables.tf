# VPC configuration
variable "cidr_vpc" {
    default = "10.0.0.0/16"
}

variable "environment_tag" {
    default = "Production"
}


variable "availability_zone" {
    default = "us-east-1a"
}

variable "cidr_public_subnet" {
    default = "10.0.1.0/24"
}


variable "cidr_private_subnet" {
    default = "10.0.2.0/24"
}


variable "instance_ami" {
    default = "ami-0b69ea66ff7391e80"
}

variable "instance_type" {
    default = "t2.micro"
}

variable "key_name" {
    default = "terraform"
}
