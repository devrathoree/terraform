# Define VPC
resource "aws_vpc" "jenkins-vpc" {
  cidr_block            = "10.0.0.0/16"
  enable_dns_support    = true
  enable_dns_hostnames  = true
  tags = {
    Name = "jenkins-vpc"
  }
}

# Define Subnet within the VPC
resource "aws_subnet" "jenkins-subnet-1a" {
  vpc_id                  = aws_vpc.jenkins-vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "jenkins-subnet-1a"
  }
}

resource "aws_subnet" "jenkins-subnet-1b" {
  vpc_id                  = aws_vpc.jenkins-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "jenkins-subnet-1b"
  }
}

# Create Route Table
resource "aws_route_table" "jenkins-rt" {
  vpc_id = aws_vpc.jenkins-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins-igw.id
  }
  tags = {
    Name = "jenkins-rt"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "jenkins-association-1a" {
  subnet_id      = aws_subnet.jenkins-subnet-1a.id
  route_table_id = aws_route_table.jenkins-rt.id
}

resource "aws_route_table_association" "jenkins-association-1b" {
  subnet_id      = aws_subnet.jenkins-subnet-1b.id
  route_table_id = aws_route_table.jenkins-rt.id
}

# Create Internet Gateway
resource "aws_internet_gateway" "jenkins-igw" {
  vpc_id = aws_vpc.jenkins-vpc.id
  tags = {
    Name = "jenkins-igw"
  }
}

# Define Security Group within the VPC
resource "aws_security_group" "jenkins-sg" {
  vpc_id      = aws_vpc.jenkins-vpc.id
  name        = "jenkins-sg"
  description = "Allow inbound SSH, HTTP, and Jenkins traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

# Define EC2 Instance and associate it with the subnet and security group
resource "aws_instance" "jenkins-ec2" {
  ami                    = "ami-0fc5d935ebf8bc3bc" 
  instance_type          = "t2.micro"
  key_name               = "nvirginia"
  subnet_id              = aws_subnet.jenkins-subnet-1a.id
  vpc_security_group_ids = [aws_security_group.jenkins-sg.id]
  tags = {
    Name = "Jenkins-instance"
  }


  # Use remote-exec provisioner to install Jenkins on Ubuntu
  provisioner "remote-exec" {
      inline = [
        "sudo apt-get update",
        "sudo apt-get install -y software-properties-common",
        "sudo add-apt-repository --yes ppa:adoptopenjdk/ppa",
        "sudo apt-get update",
        "sudo apt-get install -y adoptopenjdk-11-hotspot",
        "sudo apt install openjdk-11-jdk -y",  # Install Java
        <<EOT
  sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
  echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
  EOT
        ,
        "sudo apt-get update",
        "sudo apt-get install -y jenkins",        # Install Jenkins
        "sudo systemctl enable jenkins",
        "sudo apt install docker.io -y",
        "sudo usermod -aG docker jenkins",
        "sudo usermod -aG docker ubuntu",
#        "sudo systemctl restart docker",
      ]


    connection {
      type     = "ssh"
      user     = "ubuntu"  # For Ubuntu, the default user is usually 'ubuntu'
      private_key = file("/home/abc/Downloads/nvirginia.pem")  # Replace with the actual path to your private key
      host        = aws_instance.jenkins-ec2.public_ip
  }
}

}

data "aws_iam_role" "cluster_role" {
  name = "eksctl-test-cluster-cluster-ServiceRole-qA6vXw8sFh1r"
}
data "aws_iam_role" "NG_role" {
  name = "eksctl-test-cluster-nodegroup-linu-NodeInstanceRole-tuolIdjBxbhh"
}

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.cluster_role.arn

  vpc_config {
  subnet_ids      = [aws_subnet.jenkins-subnet-1a.id, aws_subnet.jenkins-subnet-1b.id]
  }
}


resource "aws_eks_node_group" "NG_name" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = var.node_group_name
  node_role_arn   = data.aws_iam_role.NG_role.arn
  subnet_ids      = [aws_subnet.jenkins-subnet-1a.id, aws_subnet.jenkins-subnet-1b.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}
