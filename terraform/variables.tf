variable "aws_region" {
  description = "AWS region for Project 4"
  type        = string
  default     = "af-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the Project 4 VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones used by the Project 4 VPC"
  type        = list(string)
  default = [
    "af-south-1a",
    "af-south-1b",
    "af-south-1c"
  ]
}