provider "aws" {
    region = "ap-south-1"
}

terraform {
    backend "s3" {
        region = "ap-south-1"
        bucket = "my-source-buket123"
        key = "./terraform.tfstate"
    }
}

data "aws_security_group" "existing_sg" {
    name = "launch-wizard-1"
    vpc_id = "vpc-09bc2175df40869c8"

}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  to_port           = 22
  protocol          = "TCP"
  from_port         = 22
  cidr_blocks        =   ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.existing_sg.id
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  to_port           = 80
  protocol          = "TCP"
  from_port         = 80
  cidr_blocks        =   ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.existing_sg.id
}

resource "aws_instance" "new-instance" {
    ami = "ami-0e670eb768a5fc3d4"
    instance_type = "t2.micro"
    key_name = "new-key"
    vpc_security_group_ids = [data.aws_security_group.existing_sg.id]

    connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = file("./private.pem")
        host     = self.public_ip
    }

    provisioner "remote-exec" {
    inline = [
        "sudo yum install httpd -y",
        "sudo systemctl start httpd",
        "sudo systemctl enable httpd"
        ]
    }

    provisioner "local-exec" {
        command = "mkdir /new"
    }

    provisioner "local-exec" {
        command = "echo 'Hello,Abhimanyu Patil' > /new/index.html"
        # command = "echo ${self.public_ip} >> ips.txt"
    }
    
    provisioner "file" {
        source = "${path.module}/new/index.html"
        destination = "/var/www/html/index.html"
    }
}
