# Laboratorio 8 · Solución y verificación final

**Tiempo:** 10 minutos · **Uso:** facilitador y participantes que se quedaron atrás

---

## 1. Aplicar todo

```powershell
.\scripts\apply-fix.ps1 -Lab all
```

```bash
bash scripts/apply-fix.sh all
```

Esto aplica, en orden:

| Lab | Cambio |
|---|---|
| 1 | `appsettings.Development.json` sin credenciales |
| 2 | `EmployeesController` con política de acceso + CORS cerrado |
| 3 | `Newtonsoft.Json` 12.0.1 → 13.0.3 + lock regenerado |
| 4 | `Dockerfile` multi-stage, chiseled, no root |
| 5 | `deployment.yaml` endurecido + Terraform cerrado |
| 6 | `ci-start.yml` desactivado |

## 2. Verificar

```powershell
.\scripts\scan.ps1 all
```

```bash
bash scripts/scan.sh all
```

Resultado esperado por control:

| Control | Antes | Después |
|---|---|---|
| Secret scanning | 2 hallazgos | 0 |
| SAST | 3 hallazgos | 1–2 (los que requieren rediseño) |
| SCA | 1 HIGH | 0 |
| Container scan | decenas | puñado |
| IaC scan | 8+ | 0–1 |

> El SAST puede seguir mostrando la interpolación SQL si no reescribes el
> reporte con parámetros. Ese es el punto: hay hallazgos que no se arreglan con
> una versión nueva, se arreglan escribiendo código distinto.

## 3. La API después del arreglo

```bash
# john -> su ficha                  => 200
# john -> ficha de Finance          => 403
# payroll -> cualquier ficha        => 200
# manager Engineering -> Finance    => 403
```

## 4. Restaurar el estado vulnerable

Si necesitas repetir el taller (o el repo es tu material de práctica):

```bash
git checkout -- .
git clean -fd
```

Si no clonaste con git, guarda una copia del repositorio antes de aplicar
arreglos:

```powershell
Copy-Item . ..\securehr-devsecops-lab-BACKUP -Recurse
```

## 5. Checklist de "terminado"

- [ ] La API compila y los tests pasan (`dotnet test`).
- [ ] `gitleaks` sale en 0 contra el repositorio limpio.
- [ ] `semgrep` no reporta credenciales ni CORS abierto.
- [ ] `trivy fs` no reporta dependencias HIGH/CRITICAL.
- [ ] `trivy image` muestra un conteo sustancialmente menor.
- [ ] `trivy config` no reporta hallazgos HIGH/CRITICAL en `infra/`.
- [ ] El pipeline tiene 7 jobs y un gate que bloquea.
- [ ] Existe una política de severidades escrita (aunque sea de una página).

## 6. Lo que este repositorio NO resuelve

Esto es tan importante como la lista anterior:

- **DAST** (probar la aplicación en ejecución, no el código).
- **Threat modeling** (decidir qué puede salir mal *antes* de escribir).
- **Gestión de identidades y secretos** en serio (Vault, OIDC, rotación).
- **Seguridad en runtime** (detección de comportamiento anómalo, Falco, eBPF).
- **SBOM** y firma de artefactos (Sigstore, attestations, SLSA).
- **Métricas de seguridad** (MTTR de vulnerabilidades, cobertura de controles).
- **Respuesta a incidentes** (qué hacer cuando el gate no estaba mirando).

Un taller de dos horas te deja el 20 % que evita el 80 % de los incidentes
evitables. El otro 20 % es un programa de seguridad, y eso es un viaje, no una
tarde.
