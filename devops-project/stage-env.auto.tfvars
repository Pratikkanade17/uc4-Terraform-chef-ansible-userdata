# Environment
environment = "stage"
# VPC Variables
vpc_name = "myStageVPC"
vpc_cidr_block = "10.0.0.0/16"
vpc_availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
vpc_public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
vpc_private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
vpc_database_subnets= ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
vpc_create_database_subnet_group = true 
vpc_create_database_subnet_route_table = true   
vpc_enable_nat_gateway = true  
vpc_single_nat_gateway = true

# EC2 Instance Variables
instance_type = "t3.micro"
instance_keypair = "ethans-devops-735"
private_instance_count = 2

# DNS Name
dns_name = "stage.bestcloudtraining.com"