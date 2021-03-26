variable "ami_name" {
  type    = string
  default = "my_custom_ami"  
}

variables {
    aws_access_key = ""
    aws_secret_key = ""
}


locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "linux2" {
  access_key    = "${var.aws_access_key}"
  secret_key    = "${var.aws_secret_key}"
  ami_name      = "awx ami ${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-east-1"  
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }  
  ssh_username = "ec2-user"
}

build {
  sources = ["source.amazon-ebs.linux2"]

  provisioner "shell" {
    inline = [
        "sudo yum update -y",                
        "sudo amazon-linux-extras install epel -y",        
        "sudo yum install git -y",
        "sudo amazon-linux-extras install docker -y",
        "sudo systemctl start docker",
        "sudo systemctl enable docker",
        "sudo usermod -a -G docker ec2-user",            
        "sudo yum install -y  python3-pip",
        "sudo python3 -m pip install --user --upgrade pip",
        "sudo python3 -m pip install ansible",        
        "sudo python3 -m pip install docker-compose",
        "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose", 
        "sudo pip3 install docker"  
    ]
  }
}