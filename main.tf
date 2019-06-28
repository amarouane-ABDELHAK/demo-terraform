# VARIABLES
variable "region" {
    type = "string"
    default = "us-east-1"
}
variable "access_key" {}
variable "secret_key" {}
variable "web_server_port" {}

variable "my_ip" {
  
}
variable "account_num" {
  
}

# Provider
provider "aws" {
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}


# EC2 instance 
resource "aws_instance" "myfirstec2" {
    ami = "ami-0756fbca465a59a30"
    instance_type = "t2.micro"
    vpc_security_group_ids =["${aws_security_group.amaroune-sg.id}"]
    key_name = "amarouane_pub"
    user_data = <<-EOF
                #!/bin/bash
                yum install httpd -y
                echo "Hello world. I am  up and running" >> /var/www/html/index.html
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
  

# LAMBDAS
resource "aws_lambda_function" "lambda_parse" {
  filename      = "${path.module}/lambdas/input_parser/parse_inputs.zip"
  function_name = "parse_inputs"
  role          = "arn:aws:iam::${var.account_num}:role/earthdatacd-app-lambda-processing"
  handler       = "parse_inputs.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filemd5("lambdas/input_parser/parse_inputs.zip")}"

  runtime = "python3.7"

}

resource "aws_lambda_function" "lambda_compute_delta" {
  filename      = "${path.module}/lambdas/compute_delta/handler.zip"
  function_name = "compute_delta"
  role          = "arn:aws:iam::${var.account_num}:role/earthdatacd-app-lambda-processing"
  handler       = "handler.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filemd5("lambdas/compute_delta/handler.py")}"

  runtime = "python3.7"

}

resource "aws_lambda_function" "lambda_compute_x1" {
  filename      = "${path.module}/lambdas/compute_x/handler.zip"
  function_name = "compute_x1"
  role          = "arn:aws:iam::${var.account_num}:role/earthdatacd-app-lambda-processing"
  handler       = "handler.handler_x1"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filemd5("lambdas/compute_x/handler.zip")}"

  runtime = "python3.7"

}


resource "aws_lambda_function" "lambda_compute_x2" {
  filename      = "${path.module}/lambdas/compute_x/handler.zip"
  function_name = "compute_x2"
  role          = "arn:aws:iam::${var.account_num}:role/earthdatacd-app-lambda-processing"
  handler       = "handler.handler_x2"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filemd5("lambdas/compute_x/handler.zip")}"

  runtime = "python3.7"

}

resource "aws_lambda_function" "lambda_result" {
  filename      = "${path.module}/lambdas/result/handler.zip"
  function_name = "result"
  role          = "arn:aws:iam::${var.account_num}:role/earthdatacd-app-lambda-processing"
  handler       = "handler.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filemd5("lambdas/result/handler.zip")}"

  runtime = "python3.7"

}



resource "aws_sfn_state_machine" "sfn_state_machine_equation" {
  name     = "quadratic_equation_solution"
  role_arn = "arn:aws:iam::${var.account_num}:role/ghrccd-steprole"

  definition = <<EOF
{
  "Comment": "Quadratic equation solutions",
  "StartAt": "ParseValues",
  "States": {
    "ParseValues" : {
        "Type": "Task",
        "Resource": "${aws_lambda_function.lambda_parse.arn}",
        "Next": "ComputeDelta"
    },
    "ComputeDelta" : {
        "Type": "Task",
        "Resource": "${aws_lambda_function.lambda_compute_delta.arn}",
        "Next": "ComputeX"
    },
    
    "ComputeX": {
      "Type": "Parallel",
      "Next": "Result",
       "Branches": [
      {
        "StartAt": "computeX1",
        "States": {
          "computeX1": {
            "Type": "Task",
            "Resource": "${aws_lambda_function.lambda_compute_x1.arn}",
            "End": true
          }
        }
      },
      {
        "StartAt": "computeX2",
        "States": {
          "computeX2": {
            "Type": "Task",
            "Resource": "${aws_lambda_function.lambda_compute_x2.arn}",
            "End": true
          }
        }
      }
    ]
      
  },
  "Result": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_result.arn}",
      "End":true
    }

}
}
EOF
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

output "lambda-parse-arn" {
  value = "${aws_lambda_function.lambda_parse.arn}"
}

output "lambda-compute-delta-arn" {
  value = "${aws_lambda_function.lambda_compute_delta.arn}"
}


output "lambda-compute-x1" {
  value = "${aws_lambda_function.lambda_compute_x1.last_modified}"
}




