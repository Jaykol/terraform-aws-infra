# Terraform AWS Infrastructure

Production-grade AWS infrastructure provisioned with Terraform — VPC, EC2, RDS PostgreSQL, and security groups, fully codified and repeatable.

## Architecture
```
Internet → IGW → Public Subnets (EC2) → Private Subnets (RDS)
```

- **VPC** — isolated network with public and private subnets across 2 availability zones
- **EC2** — t4g.micro (ARM64) application server with Docker pre-installed via user_data
- **RDS** — PostgreSQL 15, db.t3.micro, private subnets, no public access
- **Security Groups** — EC2 (22, 80, 443, 5000) and RDS (5432 from EC2 only)

## Resources Provisioned

| Resource | Count | Purpose |
|----------|-------|---------|
| VPC | 1 | Isolated network |
| Public Subnets | 2 | EC2, across 2 AZs |
| Private Subnets | 2 | RDS, across 2 AZs |
| Internet Gateway | 1 | Public internet access |
| Route Table | 1 | Routes public subnet traffic |
| Security Groups | 2 | EC2 and RDS firewall rules |
| EC2 Instance | 1 | Application server |
| RDS Instance | 1 | Managed PostgreSQL database |
| DB Subnet Group | 1 | RDS subnet configuration |
| Key Pair | 1 | SSH access |

## Usage

**Prerequisites:** Terraform >= 1.0, AWS CLI configured, SSH key at ~/.ssh/id_ed25519.pub

**1. Clone the repo:**
```bash
git clone https://github.com/Jaykol/terraform-aws-infra.git
cd terraform-aws-infra
```

**2. Create terraform.tfvars:**
```bash
cat > terraform.tfvars << 'EOF'
db_password = "YourStrongPassword123"
EOF
```

**3. Initialise and apply:**
```bash
terraform init
terraform plan
terraform apply
```

**4. Get outputs:**
```bash
terraform output ec2_public_ip
terraform output rds_endpoint
terraform output database_url  # sensitive — use: terraform output -raw database_url
```

**5. Destroy when done:**
```bash
terraform destroy
```

## Security Decisions

- RDS has no public access — only reachable from inside the VPC
- RDS security group scoped to EC2 security group — not open to all VPC IPs
- Database password in terraform.tfvars — excluded from version control via .gitignore
- EC2 user_data installs Docker automatically — no manual SSH configuration needed

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| aws_region | AWS region | us-east-1 |
| project_name | Used to name/tag all resources | terraform-aws-infra |
| vpc_cidr | VPC CIDR block | 10.0.0.0/16 |
| instance_type | EC2 instance type | t4g.micro |
| db_username | RDS master username | taskuser |
| db_password | RDS master password | **required** |
| db_name | Database name | taskdb |

## Author

Jesutofunmi Ajekola — [GitHub](https://github.com/Jaykol) | [LinkedIn](https://www.linkedin.com/in/jesutofunmij)
