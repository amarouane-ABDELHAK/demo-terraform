
variable "region" {
    type = "string"
    default = "us-east-1"
}
variable "access_key" {}
variable "secret_key" {}
variable "web_server_port" {}

variable "my_ip" {
  
}



provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

resource "aws_instance" "myfirstec2" {
    ami = "ami-0756fbca465a59a30"
    instance_type = "t2.micro"
    vpc_security_group_ids =["${aws_security_group.amaroune-sg.id}"]
    key_name = "amarouane_pub"
    user_data = <<-EOF
                #!/bin/bash
                yum install httpd -y
                echo "Hello dear. I am  up and running" >> /var/www/html/index.html
                yum update -y
                service httpd start
                EOF
    tags = {
        Name = "Create EC2 stuff"
    }
}



resource "aws_sqs_queue" "firstqueue" {
    name = "s3-backed-usecase-1"
}


resource "aws_security_group" "amaroune-sg" {
    name = "amarouane-sg"
    # Let's inbound
    ingress {
        from_port = "${var.web_server_port}"
        to_port = "${var.web_server_port}"
        protocol = "tcp"
        cidr_blocks = ["${var.my_ip}/32"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.my_ip}/32"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }
}
  
# }
# Problem : If you change the zip content but you kept the same name 
# The S3 object will not be updated ???


#Problem the output string is restricted 
output "ec2_public_ip" {
  value = "${aws_instance.myfirstec2.public_ip}"
}

output "sqs-1-name" {
  value = "${aws_sqs_queue.firstqueue.name}"
}




