# Preparación del entorno

Tres caminos. Elige uno **antes** del taller y verifícalo en 5 minutos.

| Camino | Ideal para | Tiempo de preparación |
|---|---|---|
| A · GitHub Codespaces (recomendado) | cualquiera, cero instalación | 3 min |
| B · Docker Desktop + .NET SDK | laptop propia | 10 min |
| C · Herramientas nativas | sin Docker | 15 min |

---

## Camino A · GitHub Codespaces

1. Sube este repositorio a GitHub (o usa el que te entrega el facilitador).
2. **Code → Codespaces → Create codespace on main.**
3. El `devcontainer` instala .NET 8, Docker, Trivy, Gitleaks y Semgrep.
4. Verifica:

```bash
dotnet --version
trivy --version
gitleaks version
semgrep --version
```

Todo el grupo con el mismo entorno, el mismo día, sin excusas de "en mi máquina
funciona". Si hay poco ancho de banda en el evento, este es el camino.

---

## Camino B · Docker Desktop + .NET SDK

### Qué necesitas

- **.NET 8 SDK** — https://dotnet.microsoft.com/download/dotnet/8.0
- **Docker Desktop** — https://www.docker.com/products/docker-desktop/
- **Git**

### Pre-descarga las imágenes (importante)

El evento suele tener wifi compartida. Descarga antes:

```bash
docker pull mcr.microsoft.com/dotnet/sdk:8.0
docker pull mcr.microsoft.com/dotnet/aspnet:8.0
docker pull zricethezav/gitleaks:latest
docker pull semgrep/semgrep:latest
docker pull aquasec/trivy:latest
```

### Pre-calienta la base de datos de vulnerabilidades de Trivy

Es la descarga más grande (~800 MB en frío) y es lo único que puede hacerte
perder 10 minutos del taller:

```bash
docker run --rm -v trivy-cache:/root/.cache/ aquasec/trivy:latest image --download-db-only
```

### Pre-restaura los paquetes NuGet

```bash
dotnet restore SecureHR.sln
```

### Verifica

```bash
dotnet run --project src/SecureHR.Api     # debe escuchar en 5080
docker info                                # debe responder sin error
```

---

## Camino C · Herramientas nativas

### Windows

```powershell
winget install Gitleaks.Gitleaks
winget install AquaSecurity.Trivy
winget install Python.Python.3.12
pip install semgrep
```

### macOS

```bash
brew install gitleaks trivy semgrep
```

### Linux

```bash
sudo apt-get install -y gitleaks trivy || true
python3 -m pip install --user semgrep
```

### Verifica

```powershell
gitleaks version
trivy --version
semgrep --version
dotnet --version
```

---

## Problemas típicos (y su solución)

### `docker: command not found` o `Cannot connect to the Docker daemon`

Docker Desktop no está arrancado. Ábrelo y espera a que diga **running**.
En Linux: `sudo systemctl start docker`.

### Trivy tarda una eternidad la primera vez

Está bajando la base de datos de vulnerabilidades. Es normal una sola vez.

```bash
# si estás sin internet, el escaneo de CVEs no puede funcionar:
trivy fs --scanners misconfig .      # solo configuración
```

### `NU1101: Unable to find package` al hacer restore

Sin conexión a nuget.org. Conecta a internet y vuelve a intentar, o usa
Codespaces.

### Semgrep no encuentra nada

Verifica que estás en la raíz del repositorio y que existe `.semgrep/securehr.yml`:

```bash
semgrep scan --config .semgrep/securehr.yml --error --quiet .
```

### El pipeline de GitHub Actions falla en `container` o `sca`

Es esperado: el pipeline de antes falla porque **debe** fallar. Ese es el
Laboratorio 7.

### Puerto 5080 ocupado

```bash
dotnet run --project src/SecureHR.Api --urls http://localhost:5090
```

---

## Anti-checklist

Si alguna de estas es verdad, resuélvelo antes de entrar a la sala:

- [ ] Nunca he ejecutado Docker en esta máquina.
- [ ] No tengo .NET 8 (tengo .NET 6 o solo .NET Framework).
- [ ] Mi laptop está al 15 % de batería y no traje cargador.
- [ ] Estoy usando una cuenta corporativa que bloquea la instalación de binarios.

Cualquiera de estas se resuelve con **Codespaces**. Úsalo.
