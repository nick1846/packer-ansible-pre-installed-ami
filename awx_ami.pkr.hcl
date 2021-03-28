
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
  instance_type = "t2.medium"
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

# a build block invokes sources and runs provisioning steps on them.
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
        "sudo pip3 install docker",  
        "git clone https://github.com/nick1846/ansible-awx.git"          
    ]
  }
  provisioner "ansible-local" {
         staging_directory = "/home/ec2-user/ansible/linux-users"        
         playbook_dir  = "../Linux_Users_Role"
         group_vars =  "../Linux_Users_Role/group_vars"
         inventory_file = "../Linux_Users_Role/hosts.yaml"
         playbook_file = "../Linux_Users_Role/main.yaml"
  }  
   
  
  provisioner "shell" {
    inline = [
        "ansible-playbook -i ./ansible-awx/installer/inventory ./ansible-awx/installer/install.yml"
    ]
  }  
  
  provisioner "ansible-local" {
       
        staging_directory = "/home/ec2-user/ansible/awx-configure-tower"        
        playbook_dir  = "../AWX_Configure_Tower"
        group_vars =  "../AWX_Configure_Tower/group_vars"
        inventory_file = "../AWX_Configure_Tower/hosts"
        playbook_file = "../AWX_Configure_Tower/main.yaml"
  }  
} 
   





