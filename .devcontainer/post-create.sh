#!/usr/bin/env bash
# Pre-instalación de herramientas para GitHub Codespaces / Dev Container.
# Objetivo: que nadie pierda los primeros 15 minutos del taller instalando cosas.
set -euo pipefail

echo "==> .NET SDK"
dotnet --version

echo "==> Trivy"
if ! command -v trivy >/dev/null 2>&1; then
  TRIVY_VERSION="0.58.1"
  sudo apt-get update -qq
  sudo apt-get install -y -qq wget apt-transport-https gnupg lsb-release >/dev/null
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
    | sudo tee -a /etc/apt/sources.list.d/trivy.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq trivy="${TRIVY_VERSION}" || sudo apt-get install -y -qq trivy
fi

echo "==> Gitleaks"
if ! command -v gitleaks >/dev/null 2>&1; then
  GITLEAKS_VERSION="8.21.2"
  wget -q "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" -O /tmp/gitleaks.tgz
  sudo tar -xzf /tmp/gitleaks.tgz -C /usr/local/bin gitleaks
fi

echo "==> Semgrep"
if ! command -v semgrep >/dev/null 2>&1; then
  python3 -m pip install --quiet --upgrade semgrep
fi

echo "==> Pre-calentando la base de vulnerabilidades de Trivy (evita esperas en el Lab 3)"
trivy --quiet image --download-db-only || true

echo
echo "Versiones instaladas:"
dotnet --version || true
trivy --version || true
gitleaks version || true
semgrep --version || true
docker --version || true

echo
echo "Listo. Ejecuta:  bash scripts/scan.sh secrets"
