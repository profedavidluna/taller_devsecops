# Laboratorio 5 · Infraestructura insegura

**Tiempo:** 15 minutos · **Herramienta:** Trivy (config) · **Control:** IaC Scanning

---

## Objetivo

Comprobar que un código impecable se puede desplegar de forma insegura, y que la
configuración también se puede analizar automáticamente.

## 1. Lee el manifiesto

`infra/deployment.yaml`:

```yaml
spec:
  containers:
    - name: api
      image: securehr:latest
      securityContext:
        privileged: true
        runAsUser: 0
        allowPrivilegeEscalation: true
```

Y en el `ConfigMap`:

```yaml
ConnectionStrings__Database: "Host=db.securehr.internal;...;Password=HR20**!"
```

Pregunta: **¿qué pasa si nuestro código es impecable pero desplegamos así?**

Un contenedor privilegiado con acceso al host convierte cualquier RCE en
compromiso del nodo. Y el `ConfigMap` no está cifrado: cualquiera con permiso de
lectura en el namespace ve la contraseña de producción.

## 2. Mídelo

```powershell
.\scripts\scan.ps1 iac
```

```bash
bash scripts/scan.sh iac
```

Salida esperada (resumida):

```
infra/deployment.yaml (kubernetes)

Tests: 8 (SUCCESS: 2, FAIL: 6)

AVD-KSV-0017 (HIGH): Container 'api' should not be privileged
AVD-KSV-0012 (HIGH): Container 'api' should not run as root
AVD-KSV-0001 (MEDIUM): Container 'api' should not allow privilege escalation
AVD-KSV-0011 (MEDIUM): Container 'api' should have a CPU limit
AVD-KSV-0018 (MEDIUM): Container 'api' should have a memory limit
AVD-KSV-0008 (MEDIUM): hostNetwork should be disabled

infra/network.tf (terraform)

AVD-AWS-0107 (CRITICAL): Security group rule allows ingress from 0.0.0.0/0
AVD-AWS-0089 (LOW): Bucket does not have logging enabled
AVD-AWS-0088 (HIGH): Bucket does not have encryption enabled
```

Los IDs cambian entre versiones de Trivy; lo que importa es el mensaje.

## 3. La conversación

Un escáner de IaC no te dice cómo diseñar tu infraestructura. Te dice:

- qué permisos estás dando sin necesitarlos;
- qué está expuesto a internet;
- qué está en texto plano;
- qué no tiene límites.

Tres preguntas para el grupo:

1. Si este pod se compromete, **¿qué alcanza?** (Con `privileged: true` +
   `hostNetwork: true`: el nodo entero.)
2. ¿Por qué un `ConfigMap` no es un lugar para secretos? (No está cifrado en
   etcd por defecto y su RBAC suele ser amplio.)
3. ¿Cuánto tarda alguien en copiar este YAML a producción? (Menos de lo que
   tarda en leerlo.)

## 4. Arreglo

```powershell
.\scripts\apply-fix.ps1 -Lab 5
```

```bash
bash scripts/apply-fix.sh 5
```

Lo que cambia:

| Antes | Después | Por qué |
|---|---|---|
| `privileged: true` | `privileged: false` | el pod no necesita el host |
| `runAsUser: 0` | `runAsNonRoot: true` + `runAsUser: 10001` | contención de daño |
| `allowPrivilegeEscalation: true` | `false` + `capabilities.drop: ALL` | sin escalada |
| sin `resources` | `requests` y `limits` | evita vecino ruidoso y DoS |
| `hostNetwork: true` | eliminado | aislamiento de red |
| `ConfigMap` | `Secret` + gestor externo | el secreto no va en el repo |
| `:latest` | `:1.4.2` | referencia inmutable |
| sin probes | `readiness` + `liveness` | el tráfico no llega a pods rotos |
| — | `readOnlyRootFilesystem: true` | el atacante no puede escribir |

Vuelve a escanear: los hallazgos de alta severidad desaparecen.

## 5. Por qué esto es DevSecOps y no "infra"

Porque el manifiesto vive en el mismo repositorio que el código, se revisa en el
mismo PR y se puede escanear en el mismo pipeline. La seguridad de
infraestructura deja de ser una revisión manual de un arquitecto y pasa a ser un
control automatizado con evidencia.

## Cierre

Casilla del día: **IaC scanning ✅**

> El código seguro desplegado de forma insegura sigue siendo un sistema inseguro.
