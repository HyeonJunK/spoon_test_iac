#spoon_test.tf

#vpc
resource "aws_vpc" "spoon_test_vpc" {

  cidr_block = "10.150.0.0/16"
  tags = {
    Name = "Spoon-test-vpc"
  }

}

#subnet-pub
resource "aws_subnet" "spoon_test_pub_sub_2a" {

  vpc_id = aws_vpc.spoon_test_vpc.id
  cidr_block = "10.150.1.0/24" 
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "Spoon-test-pub-sub-2a"
  }

}

resource "aws_subnet" "spoon_test_pub_sub_2c" {

  vpc_id = aws_vpc.spoon_test_vpc.id
  cidr_block = "10.150.2.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "Spoon-test-pub-sub-2c"
  }

}

#subnet-pri
resource "aws_subnet" "spoon_test_pri_sub_2a" {

  vpc_id = aws_vpc.spoon_test_vpc.id
  cidr_block = "10.150.11.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "Spoon-test-pri-sub-2a"
  }

}

resource "aws_subnet" "spoon_test_pri_sub_2c" {
 
  vpc_id = aws_vpc.spoon_test_vpc.id
  cidr_block = "10.150.12.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "Spoon-test-pri-sub-2c"
  }

}


#igw
resource "aws_internet_gateway" "spoon_test_igw" {

  vpc_id = aws_vpc.spoon_test_vpc.id
  tags = {
    Name = "Spoon-test-igw"
  }

}

#nat-eip
resource "aws_eip" "spoon_test_nat_gw_eip" {

  vpc   = true
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "Spoon-test-nat-gw-eip"
  }  

}

#nat-gw
resource "aws_nat_gateway" "spoon_test_nat_gw" {

  allocation_id = aws_eip.spoon_test_nat_gw_eip.id
  subnet_id = aws_subnet.spoon_test_pub_sub_2a.id
  tags = {
    Name = "Spoon-test-nat-gw"
  }

}

#rt-pub
resource "aws_route_table" "spoon_test_pub_rt" {

  vpc_id = aws_vpc.spoon_test_vpc.id
  tags = {
    Name = "Spoon-test-pub-rt"
  }

}

resource "aws_route_table_association" "spoon_test_pub_sub_2a_rt_assoc" {

  subnet_id      = aws_subnet.spoon_test_pub_sub_2a.id
  route_table_id = aws_route_table.spoon_test_pub_rt.id

}

resource "aws_route_table_association" "spoon_test_pub_sub_2c_rt_assoc" {

  subnet_id      = aws_subnet.spoon_test_pub_sub_2c.id
  route_table_id = aws_route_table.spoon_test_pub_rt.id

}

resource "aws_route" "spoon_test_pub_rt_igw" {

  route_table_id              = aws_route_table.spoon_test_pub_rt.id
  destination_cidr_block      = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.spoon_test_igw.id

}


#rt-pri
resource "aws_route_table" "spoon_test_pri_rt" {

  vpc_id = aws_vpc.spoon_test_vpc.id
  tags = {
    Name = "Spoon_test_pri_rt"
  }

}

resource "aws_route_table_association" "spoon_test_pri_sub_2a_rt_assoc" {

  subnet_id      = aws_subnet.spoon_test_pri_sub_2a.id
  route_table_id = aws_route_table.spoon_test_pri_rt.id

}

resource "aws_route_table_association" "spoon_test_pri_sub_2c_rt_assoc" {

  subnet_id      = aws_subnet.spoon_test_pri_sub_2c.id
  route_table_id = aws_route_table.spoon_test_pri_rt.id

}

resource "aws_route" "spoon_test_pri_rt_nat" {

  route_table_id              = aws_route_table.spoon_test_pri_rt.id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.spoon_test_nat_gw.id

}

#sg

resource "aws_security_group" "spoon_test_alb_sg" {
  name = "spoon-test-alb-sg"
  vpc_id = aws_vpc.spoon_test_vpc.id
  ingress {
    from_port = 80
    to_port = 80       
    protocol = "tcp"      
    cidr_blocks = ["0.0.0.0/0"] 
}
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Spoon-test-alb-sg"
  }

}

resource "aws_security_group" "spoon_test_ec2_sg" {
  name = "spoon-test-ec2-sg"
  vpc_id = aws_vpc.spoon_test_vpc.id
  ingress {
    from_port = 80
    to_port = 80    
    protocol = "tcp"      
    security_groups = [aws_security_group.spoon_test_alb_sg.id]
            
} 
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags = { 
    Name = "Spoon-test-ec2-sg"
  }

}


#alb 
resource "aws_lb" "spoon_test_alb" {
  name = "spoon-test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.spoon_test_alb_sg.id]
  subnets            = [aws_subnet.spoon_test_pub_sub_2a.id, aws_subnet.spoon_test_pub_sub_2c.id]
  tags = {
    Name = "Spoon-test-alb"
  }

}

resource "aws_lb_target_group" "spoon_test_alb_tg" {
  name = "spoon-test-alb-tg"
  vpc_id   = aws_vpc.spoon_test_vpc.id
  port     = 80
  protocol = "HTTP"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name    = "Spoon-test-alb-tg"
  }

}

resource "aws_lb_listener" "spoon_test_alb_listner" {

  load_balancer_arn = aws_lb.spoon_test_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-northeast-2:315546787604:certificate/58039fec-fb5c-4ee5-954f-9d976e0e40f2"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spoon_test_alb_tg.arn
  }

}

resource "aws_lb_listener" "spoon_test_alb_listner_80" {
  load_balancer_arn = aws_lb.spoon_test_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#asg
resource "aws_launch_template" "spoon_test_asg_lt" {
  name = "spoon-test-asg-lt"
  image_id      = "ami-013218fccb68a90d4"
  instance_type = "t2.micro"
  user_data = "${base64encode(file("user_data.sh"))}"
  vpc_security_group_ids = [aws_security_group.spoon_test_ec2_sg.id]	
}

resource "aws_autoscaling_group" "spoon_test_asg" {
  name = "spoon-test-asg"
  vpc_zone_identifier = [aws_subnet.spoon_test_pri_sub_2a.id, aws_subnet.spoon_test_pri_sub_2c.id]       
  desired_capacity   = 2
  max_size           = 2
  min_size           = 1
  launch_template {
    id      = aws_launch_template.spoon_test_asg_lt.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.spoon_test_alb_tg.arn]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "spoon-test-AS"
    propagate_at_launch = true
  }

}

#route53

resource "aws_route53_record" "spoon" {
  zone_id = "Z2AZBOXTZVB13G"
  name    = "spoon.chicorita-dev.com"
  type    = "A"

  alias {
    name                   = aws_lb.spoon_test_alb.dns_name
    zone_id                = aws_lb.spoon_test_alb.zone_id
    evaluate_target_health = true
  }
}


