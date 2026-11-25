#!/usr/bin/env bash
# Pre-instalación de herramientas para GitHub Codespaces / Dev Container.
# Objetivo: que nadie pierda los primeros 15 minutos del taller instalando cosas.
#
# Cada bloque es tolerante a fallos: si una descarga no funciona, el contenedor
# abre igual, se avisa y se sigue. El taller se puede hacer con Docker aunque
# falte el binario local (los scripts caen a las imágenes oficiales).

set -uo pipefail

ok()   { printf '  \033[0;32m[ok]\033[0m %s\n' "$1"; }
warn() { printf '  \033[1;33m[aviso]\033[0m %s\n' "$1"; }

echo "==> .NET"
if v=$(dotnet --version 2>/dev/null); then ok "dotnet $v"; else warn "dotnet no responde"; fi

# ------------------------------------------------------------------ Trivy
echo "==> Trivy"
if command -v trivy >/dev/null 2>&1; then
    ok "trivy ya estaba instalado"
elif (
        set -e
        sudo apt-get update -qq
        sudo apt-get install -y -qq wget apt-transport-https gnupg lsb-release >/dev/null
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
            | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg >/dev/null
        codename="$(lsb_release -sc)"
        echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb ${codename} main" \
            | sudo tee /etc/apt/sources.list.d/trivy.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq trivy
    ); then
    ok "trivy instalado"
else
    warn "no se pudo instalar trivy; los scripts usarán la imagen aquasec/trivy"
fi

# --------------------------------------------------------------- Gitleaks
echo "==> Gitleaks"
if command -v gitleaks >/dev/null 2>&1; then
    ok "gitleaks ya estaba instalado"
else
    GITLEAKS_VERSION="8.21.2"
    if (
        set -e
        wget -q "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" -O /tmp/gitleaks.tgz
        sudo tar -xzf /tmp/gitleaks.tgz -C /usr/local/bin gitleaks
    ); then
        ok "gitleaks instalado"
    else
        warn "no se pudo instalar gitleaks; los scripts usarán la imagen zricethezav/gitleaks"
    fi
fi

# ---------------------------------------------------------------- Semgrep
echo "==> Semgrep"
if command -v semgrep >/dev/null 2>&1; then
    ok "semgrep ya estaba instalado"
elif command -v pipx >/dev/null 2>&1 && pipx install semgrep >/dev/null 2>&1; then
    ok "semgrep instalado con pipx"
elif command -v python3 >/dev/null 2>&1; then
    installed=0
    for flags in "--break-system-packages" "--user --break-system-packages" ""; do
        # shellcheck disable=SC2086
        if python3 -m pip install --quiet --upgrade $flags semgrep >/dev/null 2>&1; then
            installed=1
            break
        fi
    done
    if [ "$installed" -eq 1 ]; then
        ok "semgrep instalado"
    else
        warn "no se pudo instalar semgrep; los scripts usarán la imagen semgrep/semgrep"
    fi
else
    warn "sin python3 no hay semgrep local; los scripts usarán la imagen semgrep/semgrep"
fi

# ------------------------------------------------- base de datos de Trivy
echo "==> Base de datos de vulnerabilidades de Trivy"
if command -v trivy >/dev/null 2>&1; then
    if trivy --quiet image --download-db-only >/dev/null 2>&1; then
        ok "base de datos descargada (el Lab 3 no esperará)"
    else
        warn "no se pudo precalentar la base; la primera ejecución tardará un poco"
    fi
fi

echo
echo "==> Resumen"
for line in "dotnet --version" "trivy --version" "gitleaks version" "semgrep --version"; do
    # shellcheck disable=SC2086
    if out=$($line 2>/dev/null | head -n1) && [ -n "$out" ]; then
        printf '  %-18s %s\n' "${line%% *}" "$out"
    else
        printf '  %-18s %s\n' "${line%% *}" "(no disponible, se usará Docker)"
    fi
done

echo
echo "Listo. Ejecuta:  bash scripts/scan.sh secrets"
