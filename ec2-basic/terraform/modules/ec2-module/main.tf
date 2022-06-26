resource "aws_instance" "myec2" {
   ami = "ami-09439f09c55136ecf"
   instance_type = var.basic_ec2_type
}
