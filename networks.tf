resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-jenkins"
  }
}

resource "aws_vpc" "vpc_worker" {
  provider             = aws.region-worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

resource "aws_internet_gateway" "igw-master" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id

  tags = {
    Name = "igw-master"
  }
}
resource "aws_internet_gateway" "igw-worker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker.id

  tags = {
    Name = "igw-worker"
  }
}
data "aws_availability_zones" "availability_zone" { #chack availability zone
  provider = aws.region-master
  state    = "available"
}

resource "aws_subnet" "subnet-1" {
  provider          = aws.region-master
  availability_zone = data.aws_availability_zones.availability_zone.names[0]
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "subnet-1"
  }
}
resource "aws_subnet" "subnet-2" {
  provider          = aws.region-master
  availability_zone = data.aws_availability_zones.availability_zone.names[1]
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "subnet-2"
  }
}

resource "aws_subnet" "subnet-3-worker" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_worker.id
  cidr_block = "192.168.1.0/24"
  tags = {
    Name = "subnet-3-worker"
  }
}

resource "aws_vpc_peering_connection" "peering" { #pearing between zones
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.vpc_worker.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region-worker
  tags = {
    Name = "master-peer"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" { #accepting  pearing between zones
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  auto_accept               = true

  tags = {
    Name = "worker-peer"
    Side = "Accepter"
  }
}

resource "aws_route_table" "master-route-table" { #routing table
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-master.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "master-route-table"
  }
}
resource "aws_route_table_association" "master1" { #route table association
  provider       = aws.region-master
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.master-route-table.id
}
resource "aws_route_table_association" "master2" { #route table association
  provider       = aws.region-master
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.master-route-table.id
}

resource "aws_route_table" "worker-route-table" { #routing table
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-worker.id
  }
  route {
    cidr_block                = "10.0.2.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "worker-route-table"
  }
}
resource "aws_route_table_association" "worker" { #route table association
  provider       = aws.region-worker
  subnet_id      = aws_subnet.subnet-3-worker.id
  route_table_id = aws_route_table.worker-route-table.id
}