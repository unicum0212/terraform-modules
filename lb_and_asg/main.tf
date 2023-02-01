# ===================================================ASG=======================================
resource "aws_autoscaling_group" "petclinic_asg" {
  name                 = "PetClinic-Project-ASG-${var.env}"
  launch_configuration = aws_launch_configuration.petclinic_lc.name
  min_size             = 1
  max_size             = 2
  min_elb_capacity     = 1
  vpc_zone_identifier  = [data.terraform_remote_state.admin.outputs.public_subnet_1, data.terraform_remote_state.admin.outputs.public_subnet_2]
  health_check_type    = "EC2"
  load_balancers       = [aws_elb.petclinic_elb.name]

  tag {
    key                 = "Name"
    value               = "PetClinic-ASG-${var.env}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "petclinic_lc" {
  name                        = "PetClinic-Project-LC-${var.env}"
  image_id                    = data.aws_ami.latest_ubuntu.id
  instance_type               = var.instance_type
  security_groups             = [data.terraform_remote_state.admin.outputs.petclinic_sg_prod]
  associate_public_ip_address = true
  user_data                   = file("launch-conf.sh")
  key_name                    = var.keypair
  enable_monitoring           = false
}

# ===================================================Load Balancer===========================
resource "aws_elb" "petclinic_elb" {
  name = "petclinic-elb-${var.env}"
  subnets = [
    data.terraform_remote_state.admin.outputs.public_subnet_1,
    data.terraform_remote_state.admin.outputs.public_subnet_2
  ]
  security_groups = [data.terraform_remote_state.admin.outputs.petclinic_sg_lb]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }

  /*
  listener {
    lb_port            = 443
    lb_protocol        = "https"
    instance_port      = 80
    instance_protocol  = "http"
    ssl_certificate_id = aws_acm_certificate.petclinic_certificate.id
  }
*/

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }

  tags = {
    Name = "PetClinic-LB-${var.env}"
  }
}

# ====================================================CloudWatch Alarm======================
resource "aws_autoscaling_policy" "petclinic_asg_up" {
  name                   = "CPU-Up-${var.env}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.petclinic_asg.name

  depends_on = [
    aws_autoscaling_group.petclinic_asg,
  ]
}

resource "aws_autoscaling_policy" "petclinic_asg_down" {
  name                   = "CPU-Down-${var.env}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.petclinic_asg.name
  depends_on = [
    aws_autoscaling_group.petclinic_asg,
  ]
}

resource "aws_cloudwatch_metric_alarm" "cpu_greater_than_80" {
  alarm_name          = "CpuUtilUpperThreshold-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  datapoints_to_alarm = "2"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.petclinic_asg.name
  }

  alarm_description = "This metric monitors cpu util, and do actions if cpu greater than 80"
  alarm_actions     = [aws_autoscaling_policy.petclinic_asg_up.arn]
  depends_on = [
    aws_autoscaling_policy.petclinic_asg_up
  ]
}

resource "aws_cloudwatch_metric_alarm" "cpu_less_than_20" {
  alarm_name          = "CpuUtilLowerThreshold-${var.env}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  datapoints_to_alarm = "2"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.petclinic_asg.name
  }

  alarm_description = "This metric monitors cpu util, and do actions if cpu less than 20"
  alarm_actions     = [aws_autoscaling_policy.petclinic_asg_down.arn]
  depends_on = [
    aws_autoscaling_policy.petclinic_asg_down
  ]
}
