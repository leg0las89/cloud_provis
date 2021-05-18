output "Master-jenkins-public-IP" {
  value = aws_instance.jenkins-master.public_ip
}

output "Worker-jenkins-pubic-IP" {
  value = {
    for instance in aws_instance.jenkins-worker :
    instance.id => instance.public_ip
  }
}