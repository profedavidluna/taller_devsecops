<#
.SYNOPSIS
    Ejecuta los escaneos del laboratorio SecureHR.

.EJEMPLO
    .\scripts\scan.ps1 secrets
    .\scripts\scan.ps1 all

.NOTAS
    - Si tienes la herramienta instalada, la usa. Si no, la ejecuta en Docker.
    - Exit code 1 significa "hay hallazgos". Eso NO es un error: es el control
      funcionando. Exit code 0 significa "nada que reportar".
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('secrets', 'sast', 'sca', 'image', 'iac', 'all', 'help')]
    [string]$Lab = 'help'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Test-Command([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-DockerReady {
    if (-not (Test-Command 'docker')) { return $false }
    docker info *> $null
    return ($LASTEXITCODE -eq 0)
}

$script:DockerReady = Test-DockerReady

function Invoke-Banner([string]$Text) {
    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor DarkCyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor DarkCyan
}

function Assert-Tool([string]$Native, [string]$Image, [string]$Hint) {
    if (Test-Command $Native) { return }
    if ($script:DockerReady) {
        Write-Host "  ($Native no está instalado: usando Docker -> $Image)" -ForegroundColor DarkGray
        return
    }
    throw "No encuentro '$Native' ni un Docker en ejecución. $Hint"
}

function Invoke-Gitleaks {
    Invoke-Banner "LAB 1 · Secret scanning (Gitleaks)"
    Assert-Tool 'gitleaks' 'zricethezav/gitleaks' 'Instala gitleaks 8.x o arranca Docker Desktop.'
    if (Test-Command 'gitleaks') {
        gitleaks detect -s . -c .gitleaks.toml --no-git --redact -v
    }
    else {
        docker run --rm -v "${RepoRoot}:/repo" zricethezav/gitleaks:latest `
            detect -s /repo -c /repo/.gitleaks.toml --no-git --redact -v
    }
}

function Invoke-Semgrep {
    Invoke-Banner "LAB 2 · SAST (Semgrep)"
    Assert-Tool 'semgrep' 'semgrep/semgrep' 'Instala semgrep (pip install semgrep) o arranca Docker Desktop.'
    if (Test-Command 'semgrep') {
        semgrep scan --config .semgrep/securehr.yml --error --quiet .
    }
    else {
        docker run --rm -v "${RepoRoot}:/src" semgrep/semgrep:latest `
            semgrep scan --config=/src/.semgrep/securehr.yml --error --quiet /src
    }
}

function Invoke-TrivyFs {
    Invoke-Banner "LAB 3 · SCA / dependencias (Trivy fs)"
    Assert-Tool 'trivy' 'aquasec/trivy' 'Instala trivy o arranca Docker Desktop.'
    if (Test-Command 'trivy') {
        trivy fs --scanners vuln --severity HIGH,CRITICAL --no-progress --skip-dirs tests .
    }
    else {
        docker run --rm -v "${RepoRoot}:/src" -v "trivy-cache:/root/.cache/" aquasec/trivy:latest `
            fs --scanners vuln --severity HIGH,CRITICAL --no-progress --skip-dirs /src/tests /src
    }
}

function Invoke-TrivyImage {
    Invoke-Banner "LAB 4 · Container scanning (Trivy image)"
    if (-not $script:DockerReady) {
        throw "Este laboratorio necesita Docker para construir y escanear la imagen."
    }
    Write-Host "  Construyendo securehr:latest ..." -ForegroundColor DarkGray
    docker build -t securehr:latest -f Dockerfile .
    if ($LASTEXITCODE -ne 0) { throw "El docker build falló. Revisa la salida anterior." }

    if (Test-Command 'trivy') {
        trivy image --severity HIGH,CRITICAL --no-progress securehr:latest
    }
    else {
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock `
            -v "trivy-cache:/root/.cache/" aquasec/trivy:latest `
            image --severity HIGH,CRITICAL --no-progress securehr:latest
    }
}

function Invoke-TrivyConfig {
    Invoke-Banner "LAB 5 · IaC / configuracion (Trivy config)"
    Assert-Tool 'trivy' 'aquasec/trivy' 'Instala trivy o arranca Docker Desktop.'
    if (Test-Command 'trivy') {
        trivy config --severity MEDIUM,HIGH,CRITICAL --no-progress infra
    }
    else {
        docker run --rm -v "${RepoRoot}:/src" -v "trivy-cache:/root/.cache/" aquasec/trivy:latest `
            config --severity MEDIUM,HIGH,CRITICAL --no-progress /src/infra
    }
}

function Show-Help {
    Write-Host @"
SecureHR DevSecOps Lab - ejecutor de escaneos

  .\scripts\scan.ps1 secrets   Secret scanning        -> Gitleaks
  .\scripts\scan.ps1 sast      Analisis de codigo     -> Semgrep
  .\scripts\scan.ps1 sca       Dependencias           -> Trivy fs
  .\scripts\scan.ps1 image     Imagen Docker          -> Trivy image
  .\scripts\scan.ps1 iac       Kubernetes + Terraform -> Trivy config
  .\scripts\scan.ps1 all       Todo, en orden

Preparacion previa (una sola vez):
  docker pull zricethezav/gitleaks:latest
  docker pull semgrep/semgrep:latest
  docker pull aquasec/trivy:latest
  dotnet restore SecureHR.sln
"@
}

switch ($Lab) {
    'secrets' { Invoke-Gitleaks }
    'sast'    { Invoke-Semgrep }
    'sca'     { Invoke-TrivyFs }
    'image'   { Invoke-TrivyImage }
    'iac'     { Invoke-TrivyConfig }
    'all' {
        Invoke-Gitleaks
        Invoke-Semgrep
        Invoke-TrivyFs
        Invoke-TrivyImage
        Invoke-TrivyConfig
    }
    default { Show-Help; return }
}

$code = $LASTEXITCODE
Write-Host ""
if ($code -eq 0) {
    Write-Host "Resultado: sin hallazgos (exit 0)." -ForegroundColor Green
}
elseif ($code -eq 1) {
    Write-Host "Resultado: HAY HALLAZGOS (exit 1). Lee la salida de arriba: eso es el control funcionando." -ForegroundColor Yellow
}
else {
    Write-Host "La herramienta terminó con exit $code. Revisa los mensajes anteriores." -ForegroundColor Red
}
exit $code
