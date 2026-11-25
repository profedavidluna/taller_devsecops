#!/usr/bin/env bash
# Ejecuta los escaneos del laboratorio SecureHR.
#
#   bash scripts/scan.sh secrets
#   bash scripts/scan.sh all
#
# Si la herramienta está instalada, la usa. Si no, la ejecuta en Docker.
# Exit code 1 = hay hallazgos (el control funcionando), no un error del script.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LAB="${1:-help}"

CYAN='\033[0;36m'; GRAY='\033[0;90m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
banner() { echo; echo "========================================================================="; echo -e "  ${CYAN}$1${NC}"; echo "========================================================================="; }

has() { command -v "$1" >/dev/null 2>&1; }
docker_ready() { has docker && docker info >/dev/null 2>&1; }

need() {
  local native="$1" image="$2" hint="$3"
  if has "$native"; then return 0; fi
  if docker_ready; then echo -e "${GRAY}  ($native no instalado: usando Docker -> $image)${NC}"; return 0; fi
  echo "ERROR: no encuentro '$native' ni Docker en ejecución. $hint" >&2
  exit 127
}

run_secrets() {
  banner "LAB 1 · Secret scanning (Gitleaks)"
  need gitleaks zricethezav/gitleaks "Instala gitleaks 8.x o arranca Docker."
  if has gitleaks; then
    gitleaks detect -s . -c .gitleaks.toml --no-git --redact -v
  else
    docker run --rm -v "$REPO_ROOT:/repo" zricethezav/gitleaks:latest \
      detect -s /repo -c /repo/.gitleaks.toml --no-git --redact -v
  fi
}

run_sast() {
  banner "LAB 2 · SAST (Semgrep)"
  need semgrep semgrep/semgrep "Instala semgrep (pip install semgrep) o arranca Docker."
  if has semgrep; then
    semgrep scan --config .semgrep/securehr.yml --error --quiet .
  else
    docker run --rm -v "$REPO_ROOT:/src" semgrep/semgrep:latest \
      semgrep scan --config=/src/.semgrep/securehr.yml --error --quiet /src
  fi
}

run_sca() {
  banner "LAB 3 · SCA / dependencias (Trivy fs)"
  need trivy aquasec/trivy "Instala trivy o arranca Docker."
  if has trivy; then
    trivy fs --scanners vuln --severity HIGH,CRITICAL --no-progress --skip-dirs tests .
  else
    docker run --rm -v "$REPO_ROOT:/src" -v trivy-cache:/root/.cache/ aquasec/trivy:latest \
      fs --scanners vuln --severity HIGH,CRITICAL --no-progress --skip-dirs /src/tests /src
  fi
}

run_image() {
  banner "LAB 4 · Container scanning (Trivy image)"
  docker_ready || { echo "ERROR: este laboratorio necesita Docker." >&2; exit 127; }
  echo -e "${GRAY}  Construyendo securehr:latest ...${NC}"
  docker build -t securehr:latest -f Dockerfile . || { echo "El docker build falló."; exit 1; }
  if has trivy; then
    trivy image --severity HIGH,CRITICAL --no-progress securehr:latest
  else
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
      -v trivy-cache:/root/.cache/ aquasec/trivy:latest \
      image --severity HIGH,CRITICAL --no-progress securehr:latest
  fi
}

run_iac() {
  banner "LAB 5 · IaC / configuración (Trivy config)"
  need trivy aquasec/trivy "Instala trivy o arranca Docker."
  if has trivy; then
    trivy config --severity MEDIUM,HIGH,CRITICAL --no-progress infra
  else
    docker run --rm -v "$REPO_ROOT:/src" -v trivy-cache:/root/.cache/ aquasec/trivy:latest \
      config --severity MEDIUM,HIGH,CRITICAL --no-progress /src/infra
  fi
}

case "$LAB" in
  secrets) run_secrets ;;
  sast)    run_sast ;;
  sca)     run_sca ;;
  image)   run_image ;;
  iac)     run_iac ;;
  all)     run_secrets; run_sast; run_sca; run_image; run_iac ;;
  *)
    cat <<'EOF'
SecureHR DevSecOps Lab - ejecutor de escaneos

  bash scripts/scan.sh secrets   Secret scanning        -> Gitleaks
  bash scripts/scan.sh sast      Análisis de código     -> Semgrep
  bash scripts/scan.sh sca       Dependencias           -> Trivy fs
  bash scripts/scan.sh image     Imagen Docker          -> Trivy image
  bash scripts/scan.sh iac       Kubernetes + Terraform -> Trivy config
  bash scripts/scan.sh all       Todo, en orden

Preparación previa (una sola vez):
  docker pull zricethezav/gitleaks:latest
  docker pull semgrep/semgrep:latest
  docker pull aquasec/trivy:latest
  dotnet restore SecureHR.sln
EOF
    exit 0 ;;
esac

code=$?
echo
if [ "$code" -eq 0 ]; then
  echo -e "${GREEN}Resultado: sin hallazgos (exit 0).${NC}"
elif [ "$code" -eq 1 ]; then
  echo -e "${YELLOW}Resultado: HAY HALLAZGOS (exit 1). Eso es el control funcionando.${NC}"
else
  echo -e "${YELLOW}La herramienta terminó con exit $code. Revisa los mensajes anteriores.${NC}"
fi
exit "$code"
