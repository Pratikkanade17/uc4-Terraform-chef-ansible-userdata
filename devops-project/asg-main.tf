
# Get latest AMI ID for Amazon Linux2 OS
data "aws_ami" "amzlinux2" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-gp2" ]
  }
  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
  filter {
    name = "architecture"
    values = [ "x86_64" ]
  }
}

# Launch Template Resource
resource "aws_launch_template" "my_launch_template" {
  name_prefix = "devops-launch-template"
  #name = "my-launch-template"
  description = "My Launch template"
  image_id = data.aws_ami.amzlinux2.id
  instance_type = var.instance_type

  vpc_security_group_ids = [ module.private_sg.security_group_id ]
  key_name = var.instance_keypair
  user_data = filebase64("${path.module}/app_install.sh")
  ebs_optimized = true 
  #default_version = 1
  update_default_version = true 
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      #volume_size = 10      
      volume_size = 20 # LT Update Testing - Version 2 of LT              
      delete_on_termination = true
      volume_type = "gp2" # default  is gp2 
    }
   }
  monitoring {
    enabled = true
  }   
 
  
}


# Autoscaling Group Resource
resource "aws_autoscaling_group" "my_asg" {
  #name_prefix = "myasg-"
  name_prefix = "devops-asg-"  
  max_size = 10
  min_size = 2
  #min_size = 4 
  desired_capacity = 2    
  #desired_capacity = 4   
  vpc_zone_identifier = module.vpc.private_subnets
  target_group_arns = module.alb.target_group_arns
  health_check_type = "ELB"
  #health_check_grace_period = 300 # default is 300 seconds
  launch_template {
    id = aws_launch_template.my_launch_template.id 
    version = aws_launch_template.my_launch_template.latest_version
  }
  # Instance Refresh
  instance_refresh {
    strategy = "Rolling"
    preferences {
      # instance_warmup = 300 # Default behavior is to use the Auto Scaling Groups health check grace period value
      min_healthy_percentage = 50            
    }
    triggers = [ "desired_capacity" ] # You can add any argument from ASG here, if those has changes, ASG Instance Refresh will trigger   
  }
  tag {
    key                 = "Owners"
    value               = "Web-Team"
    propagate_at_launch = true
  }
}

###### Target Tracking Scaling Policies ######
# TTS - Scaling Policy-1: Based on CPU Utilization
# Define Autoscaling Policies and Associate them to Autoscaling Group
resource "aws_autoscaling_policy" "avg_cpu_policy_greater_than_xx" {
  name = "avg-cpu-policy"
  policy_type = "TargetTrackingScaling" # Important Note: The policy type, either "SimpleScaling", "StepScaling" or "TargetTrackingScaling". If this value isn't provided, AWS will default to "SimpleScaling."    
  autoscaling_group_name = aws_autoscaling_group.my_asg.id 
  estimated_instance_warmup = 180 # defaults to ASG default cooldown 300 seconds if not set
  # CPU Utilization is above 50
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }  
 
}

# TTS - Scaling Policy-2: Based on ALB Target Requests
resource "aws_autoscaling_policy" "alb_target_requests_greater_than_yy" {
  name = "alb-target-requests-greater-than-yy"
  policy_type = "TargetTrackingScaling" # Important Note: The policy type, either "SimpleScaling", "StepScaling" or "TargetTrackingScaling". If this value isn't provided, AWS will default to "SimpleScaling."    
  autoscaling_group_name = aws_autoscaling_group.my_asg.id 
  estimated_instance_warmup = 120 # defaults to ASG default cooldown 300 seconds if not set  
  # Number of requests > 10 completed per target in an Application Load Balancer target group.
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label =  "${module.alb.lb_arn_suffix}/${module.alb.target_group_arn_suffixes[0]}"    
    }  
    target_value = 10.0
  }    
}

# Autoscaling Notifications
## AWS Bug for SNS Topic: https://stackoverflow.com/questions/62694223/cloudwatch-alarm-pending-confirmation
## Due to that create SNS Topic with unique name 

## SNS - Topic
resource "aws_sns_topic" "myasg_sns_topic" {
  #name = "myasg-sns-topic-${random_pet.this.id}"
  name = "devops-topic"
} 

## SNS - Subscription
resource "aws_sns_topic_subscription" "myasg_sns_topic_subscription" {
  topic_arn = aws_sns_topic.myasg_sns_topic.arn
  protocol  = "email"
  endpoint  = "devopscloudworld@gmail.com"
}

## Create Autoscaling Notification Resource
resource "aws_autoscaling_notification" "myasg_notifications" {
  group_names = [aws_autoscaling_group.my_asg.id]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
  topic_arn = aws_sns_topic.myasg_sns_topic.arn 
}
