# Infraestructura AWS de SecureHR (Laboratorio 5).
# Deliberadamente insegura. `trivy config infra/` la escanea sin necesidad de
# credenciales de AWS ni de `terraform init`.
#
# Hallazgos esperados:
#   - Security group abierto a 0.0.0.0/0 en PostgreSQL y SSH
#   - Bucket S3 sin cifrado, sin versionado y sin bloqueo de acceso público

terraform {
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "securehr_db" {
  name        = "securehr-db-sg"
  description = "Acceso a la base de datos de SecureHR"

  ingress {
    description = "PostgreSQL desde cualquier lugar (para no tener problemas de red)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH de administracion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "securehr_reports" {
  bucket = "securehr-reports-lab-2026"

  tags = {
    Owner = "people-analytics"
  }
}

# Falta: aws_s3_bucket_server_side_encryption_configuration
# Falta: aws_s3_bucket_versioning
# Falta: aws_s3_bucket_public_access_block
