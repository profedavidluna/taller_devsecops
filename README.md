# SecureHR · Laboratorio DevSecOps

> **La aplicación funciona. ¿También es segura?**

Repositorio del taller *"Tu aplicación funciona… ¿pero es segura?"* para el
**IA & Cybersecurity Day 2026**.

Una API de Recursos Humanos, un pipeline que se ve perfecto y seis controles de
seguridad que no existen. En dos horas los construimos.

---

## La historia

SecureHR tiene una API interna que usa el área de Recursos Humanos para
consultar empleados y generar reportes. Tiene CI/CD, pruebas automatizadas,
Docker y cloud. El gerente está orgulloso:

> "Ya tenemos CI/CD, Docker, pruebas automatizadas y cloud. Estamos bien."

Y la pregunta del taller:

> **¿Seguro?**

---

## Empieza en 3 comandos

```bash
dotnet restore SecureHR.sln
dotnet run --project src/SecureHR.Api
```

La API queda en `http://localhost:5080`.

```bash
curl http://localhost:5080/health
```

Después, tu primer escaneo:

```powershell
.\scripts\scan.ps1 secrets      # Windows
```

```bash
bash scripts/scan.sh secrets    # Linux / macOS / Codespaces
```

> **¿Sin herramientas instaladas?** No hace falta instalar nada: los scripts usan
> Docker automáticamente. Requisito único: Docker en ejecución. Ver [`SETUP.md`](SETUP.md).

---

## Los seis controles del taller

| # | Control | Herramienta | Comando | Pregunta que responde |
|---|---|---|---|---|
| 1 | Secret scanning | Gitleaks | `scan secrets` | ¿Estamos publicando credenciales? |
| 2 | SAST | Semgrep | `scan sast` | ¿El código tiene patrones inseguros? |
| 3 | SCA | Trivy `fs` | `scan sca` | ¿Nuestras dependencias están vulnerables? |
| 4 | Container scan | Trivy `image` | `scan image` | ¿La imagen tiene CVEs? |
| 5 | IaC scan | Trivy `config` | `scan iac` | ¿La infraestructura está mal configurada? |
| 6 | Security gate | GitHub Actions | — | ¿Qué hacemos con lo que encontramos? |

La meta del taller es pasar de **0/6 a 6/6**.

---

## Mapa del repositorio

```
securehr-devsecops-lab/
├── src/SecureHR.Api/          La aplicación (.NET 8) — funciona, es insegura
├── tests/SecureHR.Tests/      7 pruebas en verde que no ven el problema
├── Dockerfile                 Inseguro a propósito (Lab 4)
├── Dockerfile.secure          La versión corregida
├── docker-compose.yml
├── infra/
│   ├── deployment.yaml        Kubernetes con un pod privilegiado (Lab 5)
│   └── network.tf             Security group abierto a 0.0.0.0/0 (Lab 5)
├── .github/workflows/
│   ├── ci-start.yml           El pipeline "de antes"
│   └── ci-devsecops.yml       El pipeline "de después"
├── postman/                    Colección para probar la API sin curl
├── .gitleaks.toml             Reglas de detección de secretos
├── .semgrep/securehr.yml      3 reglas propias de SAST
├── labs/                      Guía paso a paso de cada laboratorio
├── scripts/                   scan + apply-fix (PowerShell y bash)
└── solution/                  Los archivos corregidos
```

### Laboratorios

| Carpeta | Tema | Tiempo |
|---|---|---|
| [`labs/01-secrets`](labs/01-secrets/README.md) | El secreto a plena vista | 15 min |
| [`labs/02-sast`](labs/02-sast/README.md) | "El endpoint funciona" (BOLA + SAST) | 20 min |
| [`labs/03-sca`](labs/03-sca/README.md) | La librería vulnerable | 20 min |
| [`labs/04-container`](labs/04-container/README.md) | El Dockerfile que funciona | 15 min |
| [`labs/05-iac`](labs/05-iac/README.md) | Infraestructura insegura | 15 min |
| [`labs/06-pipeline`](labs/06-pipeline/README.md) | Construir el pipeline | 15 min |
| [`labs/07-gates`](labs/07-gates/README.md) | Security gates | 10 min |
| [`labs/08-solution`](labs/08-solution/README.md) | Solución y verificación | 10 min |

---

## Las 6 vulnerabilidades plantadas

| # | Vulnerabilidad | Archivo | Control que la encuentra |
|---|---|---|---|
| 1 | Contraseña de BD y API key en el repo | `appsettings.Development.json` | Secret scanning |
| 2 | Sin autorización a nivel de objeto (BOLA) | `EmployeesController.cs` | **Ninguno** (criterio humano) |
| 3 | Inyección SQL por concatenación | `ReportsController.cs` | SAST |
| 4 | Dependencia con CVE conocido | `SecureHR.Api.csproj` | SCA |
| 5 | Imagen root + CVEs + secretos horneados | `Dockerfile` | Container scan |
| 6 | Pod privilegiado + SG abierto | `infra/` | IaC scan |

La #2 es la más importante del taller: **ningún escáner la encuentra**. Está ahí
para demostrar que las herramientas no reemplazan el criterio.

---

## Probar la API sin escribir curl

En [`postman/`](postman/) está la colección con las doce peticiones del taller
(BOLA, inyección, roles y estados de error), cada una con sus pruebas:

**Import → Link** y pega:

```
https://raw.githubusercontent.com/profedavidluna/taller_devsecops/main/postman/SecureHR.postman_collection.json
```

Solo hay que levantar la API y ajustar `baseUrl` (en Codespaces, la URL del
puerto 5080 reenviado). Detalle en [`postman/README.md`](postman/README.md).

---

## Verificar que el laboratorio funciona

```bash
dotnet build SecureHR.sln -c Release
dotnet test  SecureHR.sln -c Release
```

Salida esperada: build correcto y **9 pruebas en verde**.

Sí: 9 en verde con una aplicación que filtra salarios. Ese es el punto.

```bash
# La demo del BOLA (con la API corriendo)
curl -s http://localhost:5080/employees/3 \
  -H "X-Demo-User: john.doe" -H "X-Demo-Role: Employee" \
  -H "X-Demo-Department: Engineering" -H "X-Demo-EmployeeId: 7"
```

Devuelve la ficha de una persona de Finance, con salario y cédula. HTTP 200.

---

## Restaurar el estado inicial

```bash
git checkout -- .
git clean -fd
```

---

## Reglas del taller

1. **No instalar veinte cosas.** Todo está preparado; si algo falta, usa Docker.
2. **Un ejercicio, un resultado visible.** Si no ves un hallazgo en pantalla, el
   ejercicio no terminó.
3. **La herramienta no es el tema.** El tema es la decisión que tomas con lo que
   la herramienta te muestra.
4. **Si algo se rompe, se arregla en grupo.** Es un laboratorio, no un examen.

---

## Créditos

Material preparado por **David Luna** para el **IA & Cybersecurity Day 2026**.
Aplicación, pipeline y vulnerabilidades son ficticios y existen únicamente con
fines didácticos.
