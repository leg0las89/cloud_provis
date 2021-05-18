resource "aws_security_group" "master-lb" {
  provider    = aws.region-master
  name        = "allow_inbound"
  description = "Allow 443 and traffic to jenkins"
  vpc_id      = aws_vpc.vpc_master.id

  ingress {
    description = "Allow 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_443_and_80"
  }
}

resource "aws_security_group" "jenkins-master" {
  provider    = aws.region-master
  name        = "jenkins_master"
  description = "Allow 8080 / 22"
  vpc_id      = aws_vpc.vpc_master.id

  ingress {
    description     = "Allow 8080"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.master-lb.id]
  }
  ingress {
    description = "Allow 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress { # allow traffic from us-west
    description = "Allow us-west-2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "jenkins-master"
  }
}

resource "aws_security_group" "jenkins-worker" {
  provider    = aws.region-worker
  name        = "jenkins_worker"
  description = "Allow 8080 / 22"
  vpc_id      = aws_vpc.vpc_worker.id

  ingress {
    description = "Allow 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress { # allow traffic from us-west
    description = "Allow us-west-2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "jenkins-worker"
  }
}