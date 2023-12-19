# Output block to display the public IP address of the EC2 instance
output "jenkins_instance_public_ip" {
  value = aws_instance.jenkins-ec2.public_ip
}