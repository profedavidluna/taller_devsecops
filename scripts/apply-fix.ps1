<#
.SYNOPSIS
    Aplica la corrección de un laboratorio (para el facilitador o para
    quien se quedó atrás y necesita alcanzar al grupo).

.EJEMPLO
    .\scripts\apply-fix.ps1 -Lab 2
    .\scripts\apply-fix.ps1 -Lab all
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('1', '2', '3', '4', '5', '6', 'all')]
    [string]$Lab = 'all'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Copy-Solution([string]$RelativePath, [string]$TargetPath) {
    $source = Join-Path $Root (Join-Path 'solution' $RelativePath)
    $target = Join-Path $Root $TargetPath
    if (-not (Test-Path $source)) { throw "No existe el archivo de solución: $source" }
    Copy-Item $source $target -Force
    Write-Host "  [ok] $TargetPath" -ForegroundColor Green
}

function Fix-Lab1 {
    Write-Host "Lab 1 · Secretos: el archivo deja de tener credenciales" -ForegroundColor Cyan
    Copy-Solution 'src/SecureHR.Api/appsettings.Development.json' 'src/SecureHR.Api/appsettings.Development.json'
    Write-Host "  Recuerda: en la vida real esto NO termina aquí. Hay que rotar la clave" -ForegroundColor Yellow
    Write-Host "  y limpiar el historial de git. Cambiar el archivo no despublica el secreto." -ForegroundColor Yellow
}

function Fix-Lab2 {
    Write-Host "Lab 2 · Código: se aplica la política de acceso y se cierra CORS" -ForegroundColor Cyan
    Copy-Solution 'src/SecureHR.Api/Controllers/EmployeesController.cs' 'src/SecureHR.Api/Controllers/EmployeesController.cs'
    Copy-Solution 'src/SecureHR.Api/Program.cs' 'src/SecureHR.Api/Program.cs'
}

function Fix-Lab3 {
    Write-Host "Lab 3 · Dependencias: Newtonsoft.Json 12.0.1 -> 13.0.3" -ForegroundColor Cyan
    Copy-Solution 'src/SecureHR.Api/SecureHR.Api.csproj' 'src/SecureHR.Api/SecureHR.Api.csproj'
    Write-Host "  Actualizando el lock file..." -ForegroundColor DarkGray
    dotnet restore SecureHR.sln --force-evaluate *> $null
    if ($LASTEXITCODE -ne 0) { Write-Host "  Aviso: el restore falló (¿sin red?). Corre 'dotnet restore --force-evaluate'." -ForegroundColor Yellow }
}

function Fix-Lab4 {
    Write-Host "Lab 4 · Imagen: Dockerfile multi-stage, no root, base chiseled" -ForegroundColor Cyan
    Copy-Item (Join-Path $Root 'Dockerfile.secure') (Join-Path $Root 'Dockerfile') -Force
    Write-Host "  [ok] Dockerfile" -ForegroundColor Green
}

function Fix-Lab5 {
    Write-Host "Lab 5 · Infraestructura: pod sin privilegios y bucket cerrado" -ForegroundColor Cyan
    Copy-Solution 'infra/deployment.yaml' 'infra/deployment.yaml'
    Copy-Solution 'infra/network.tf' 'infra/network.tf'
}

function Fix-Lab6 {
    Write-Host "Lab 6 · Pipeline: el workflow DevSecOps ya está en .github/workflows/ci-devsecops.yml" -ForegroundColor Cyan
    $start = Join-Path $Root '.github/workflows/ci-start.yml'
    if (Test-Path $start) {
        Rename-Item $start 'ci-start.yml.old' -Force
        Write-Host "  [ok] ci-start.yml desactivado (renombrado a .old)" -ForegroundColor Green
    }
}

switch ($Lab) {
    '1' { Fix-Lab1 }
    '2' { Fix-Lab2 }
    '3' { Fix-Lab3 }
    '4' { Fix-Lab4 }
    '5' { Fix-Lab5 }
    '6' { Fix-Lab6 }
    'all' { Fix-Lab1; Fix-Lab2; Fix-Lab3; Fix-Lab4; Fix-Lab5; Fix-Lab6 }
}

Write-Host ""
Write-Host "Compilando para verificar que todo sigue en pie..." -ForegroundColor DarkGray
dotnet build SecureHR.sln -c Release --nologo -v q
if ($LASTEXITCODE -eq 0) {
    Write-Host "Build OK. Vuelve a correr los escaneos: .\scripts\scan.ps1 all" -ForegroundColor Green
}
else {
    Write-Host "El build falló. Revisa los errores de arriba." -ForegroundColor Red
    exit 1
}
