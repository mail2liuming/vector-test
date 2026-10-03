output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "availability_zones" {
  description = "AZs the subnets are spread across (same order as the subnet ID lists)."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Public subnet IDs, one per AZ."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs, one per AZ."
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "Route table used by the public subnets."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Route table used by the private subnets."
  value       = aws_route_table.private.id
}

output "nat_gateway_id" {
  description = "NAT gateway ID, or null when enable_nat_gateway is false."
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}
