# Infraestructura AWS de SecureHR — versión corregida (Laboratorio 5).

terraform {
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "us-east-1"
}

variable "office_cidr" {
  description = "Rango de la VPN corporativa. Nada más entra a la base."
  type        = string
  default     = "10.20.0.0/16"
}

resource "aws_security_group" "securehr_db" {
  name        = "securehr-db-sg"
  description = "Acceso a la base de datos de SecureHR desde la VPN corporativa"

  ingress {
    description = "PostgreSQL solo desde la red interna"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.office_cidr]
  }

  # SSH ya no está expuesto: el acceso se hace por SSM Session Manager.
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.office_cidr]
  }
}

resource "aws_s3_bucket" "securehr_reports" {
  bucket = "securehr-reports-lab-2026"

  tags = {
    Owner = "people-analytics"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "securehr_reports" {
  bucket = aws_s3_bucket.securehr_reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "securehr_reports" {
  bucket = aws_s3_bucket.securehr_reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "securehr_reports" {
  bucket = aws_s3_bucket.securehr_reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
