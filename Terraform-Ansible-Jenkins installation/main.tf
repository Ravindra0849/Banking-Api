
# Creation of Private Key  https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key

resource "tls_private_key" "rsa-4096" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

variable "key_name" {
    description = "Name of the SSH key"
    type = string
    default = "ansible-jenkins"
}

# Creating Public Key for EC2   https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "key_pair" {
    key_name   = var.key_name
    public_key = tls_private_key.rsa-4096.public_key_openssh
}

# Save Pem file Locally

resource "local_file" "private_key" {
    content = tls_private_key.rsa-4096.private_key_pem
    filename = var.key_name

    provisioner "local-exec" {
        command = "chmod 400 ${var.key_name}"
    }
}

# Create an Security Group for the SSH and HTTP Ports

resource "aws_security_group" "Sg" {
    name        = "allow_tls"
    description = "Allow TLS inbound traffic"

    ingress {
        description      = "SSH"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        description      = "HTTP"
        from_port        = 8080
        to_port          = 8080
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Sg"
    }
}

#  Create an Ec2 Instance

resource "aws_instance" "Jenkins" {
    ami = "ami-0287a05f0ef0e9d9a"
    instance_type = "t2.micro"
    key_name = aws_key_pair.key_pair.key_name
    vpc_security_group_ids = [aws_security_group.Sg.id]
    user_data = file("ansible.sh")

    tags = {
        Name = "Jenkins-Server"
    }

    root_block_device {
        volume_size = 8
        volume_type = "gp2"
    }

    provisioner "local-exec" {
        command = "touch dynamic_inventory.ini"
    }
}
# https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file
data "template_file" "inventory" {
    template = <<-EOT
    [ec2_instances]
    ${aws_instance.Jenkins.public_ip} ansible_user=ubuntu ansible_private_key_file=${path.module}/${var.key_name}
    EOT
}

resource "local_file" "dynamic_inventory" {
    depends_on = [ aws_instance.Jenkins ]

    filename = "dynamic_inventory.ini"
    content = data.template_file.inventory.rendered

    provisioner "local-exec" {
        command = "chmod 400 ${local_file.dynamic_inventory.filename}"
    }
}

# https://discuss.hashicorp.com/t/dynamic-inventory-for-ansible-using-terraform/20411

resource "null_resource" "run_ansible" {
    depends_on = [local_file.dynamic_inventory]

    provisioner "local-exec" {
        command = "ansible-playbook -i dynamic_inventory.ini ansible-jenkins.yml"
        working_dir = path.module
    }
}
