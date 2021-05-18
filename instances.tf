data "aws_ssm_parameter" "linux-ami-master" {
  provider = aws.region-master
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_ssm_parameter" "linux-ami-worker" {
  provider = aws.region-worker
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_key_pair" "master-key" {
  provider   = aws.region-master
  key_name   = "jenkins-key"
  public_key = file("C:/terraform/cloud_proj.pub")
}
resource "aws_key_pair" "worker-key" {
  provider   = aws.region-worker
  key_name   = "jenkins-key"
  public_key = file("C:/terraform/cloud_proj.pub")
}

resource "aws_instance" "jenkins-master" {
  provider                    = aws.region-master
  ami                         = data.aws_ssm_parameter.linux-ami-master.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-master.id]
  subnet_id                   = aws_subnet.subnet-1.id
  tags = {
    Name = "jenkins-master"
  }
  depends_on = [
    aws_route_table_association.master1
  ]
  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-master} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/jenkins-master-sample.yml
EOF
  }
}

resource "aws_instance" "jenkins-worker" {
  provider                    = aws.region-worker
  count                       = var.workers-count
  ami                         = data.aws_ssm_parameter.linux-ami-worker.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.worker-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-worker.id]
  subnet_id                   = aws_subnet.subnet-3-worker.id
  tags = {
    Name = join("_", ["jenkins-worker", count.index + 1])
  }
  depends_on = [
    aws_route_table_association.worker,
    aws_instance.jenkins-master
  ]
}