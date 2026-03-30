output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value = aws_instance.app.public_dns
}

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value = aws_db_instance.main.endpoint
}

output "vpc_id" {
  description = "ID of the VPC"
  value = aws_vpc.main.id
}

output "database_url" {
  description = "Full database connection string"
  value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
  sensitive = true
}
