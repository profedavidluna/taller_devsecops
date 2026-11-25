#!/usr/bin/env bash
# Aplica la corrección de un laboratorio.
#   bash scripts/apply-fix.sh 2
#   bash scripts/apply-fix.sh all
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
LAB="${1:-all}"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

copy_solution() {
  local rel="$1" dest="$2"
  cp "solution/$rel" "$dest" && echo -e "  ${GREEN}[ok]${NC} $dest"
}

fix1() {
  echo -e "${CYAN}Lab 1 · Secretos: el archivo deja de tener credenciales${NC}"
  copy_solution 'src/SecureHR.Api/appsettings.Development.json' 'src/SecureHR.Api/appsettings.Development.json'
  echo -e "  ${YELLOW}Recuerda: hay que rotar la clave y limpiar el historial de git.${NC}"
}
fix2() {
  echo -e "${CYAN}Lab 2 · Código: política de acceso aplicada + CORS cerrado${NC}"
  copy_solution 'src/SecureHR.Api/Controllers/EmployeesController.cs' 'src/SecureHR.Api/Controllers/EmployeesController.cs'
  copy_solution 'src/SecureHR.Api/Program.cs' 'src/SecureHR.Api/Program.cs'
}
fix3() {
  echo -e "${CYAN}Lab 3 · Dependencias: Newtonsoft.Json 12.0.1 -> 13.0.3${NC}"
  copy_solution 'src/SecureHR.Api/SecureHR.Api.csproj' 'src/SecureHR.Api/SecureHR.Api.csproj'
  dotnet restore SecureHR.sln --force-evaluate >/dev/null 2>&1 || echo -e "  ${YELLOW}Aviso: restore falló (¿sin red?).${NC}"
}
fix4() {
  echo -e "${CYAN}Lab 4 · Imagen: multi-stage, no root, chiseled${NC}"
  cp Dockerfile.secure Dockerfile && echo -e "  ${GREEN}[ok]${NC} Dockerfile"
}
fix5() {
  echo -e "${CYAN}Lab 5 · Infraestructura: pod sin privilegios y bucket cerrado${NC}"
  copy_solution 'infra/deployment.yaml' 'infra/deployment.yaml'
  copy_solution 'infra/network.tf' 'infra/network.tf'
}
fix6() {
  echo -e "${CYAN}Lab 6 · Pipeline: usa .github/workflows/ci-devsecops.yml${NC}"
  [ -f .github/workflows/ci-start.yml ] && mv .github/workflows/ci-start.yml .github/workflows/ci-start.yml.old \
    && echo -e "  ${GREEN}[ok]${NC} ci-start.yml desactivado"
}

case "$LAB" in
  1) fix1 ;; 2) fix2 ;; 3) fix3 ;; 4) fix4 ;; 5) fix5 ;; 6) fix6 ;;
  all) fix1; fix2; fix3; fix4; fix5; fix6 ;;
  *) echo "Uso: bash scripts/apply-fix.sh [1|2|3|4|5|6|all]"; exit 2 ;;
esac

echo
echo "Compilando para verificar..."
if dotnet build SecureHR.sln -c Release --nologo -v q; then
  echo -e "${GREEN}Build OK. Vuelve a correr: bash scripts/scan.sh all${NC}"
else
  echo "El build falló."; exit 1
fi
