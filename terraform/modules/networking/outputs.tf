output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "eks_private_subnet_ids" {
  description = "IDs das subnets privadas do EKS"
  value       = aws_subnet.eks_private[*].id
}

output "rds_private_subnet_ids" {
  description = "IDs das subnets privadas do RDS"
  value       = aws_subnet.rds_private[*].id
}

output "nat_gateway_ip" {
  description = "IP do NAT Gateway"
  value       = aws_nat_gateway.main.public_ip
}

output "eks_security_group_id" {
  description = "ID do Security Group do EKS"
  value       = aws_security_group.eks.id
}

output "rds_security_group_id" {
  description = "ID do Security Group do RDS"
  value       = aws_security_group.rds.id
}


output "lb_security_group_id" {
  value = aws_security_group.lb.id
}
