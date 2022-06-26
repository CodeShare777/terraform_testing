variable "basic_ec2_type" {
  default = "t2.micro"
}

variable "horizontal_api" {
  type = string
  default = "internal_xyz_horizontal"
}

variable "services_list" {
  type = list
  default = []
}
