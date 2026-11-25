# Laboratorio 7 · Security Gates: la decisión

**Tiempo:** 10 minutos · **Archivo:** `.github/workflows/ci-devsecops.yml` (job `security-gate`)

---

## Objetivo

Entender que un escáner produce **información**, y que un gate produce una
**decisión**. La diferencia entre las dos es una política escrita.

## 1. La votación

Proyecta esto y haz votar a mano alzada:

```
2 Critical
6 High
23 Medium
57 Low
```

> ¿Desplegamos?

Casi siempre gana el "no" para Critical y el "sí" para el resto. Luego la
pregunta que rompe el consenso:

> ¿Y si el Critical está en una librería que no se puede actualizar hasta el
> próximo trimestre, y el servicio es el portal de nómina que paga a 3.000
> personas mañana?

## 2. La política (ejemplo, no dogma)

| Severidad | Acción | Quién decide |
|---|---|---|
| CRITICAL | Bloquea el despliegue | automático |
| HIGH | Bloquea; excepción aprobada y con fecha de caducidad | líder técnico + seguridad |
| MEDIUM | Reporta, no bloquea | equipo dueño del servicio |
| LOW | Se registra para seguimiento | nadie, todavía |

Y la parte que casi nadie escribe:

- **quién** puede aprobar una excepción;
- **por cuánto tiempo** vale (con fecha de expiración, no "hasta nuevo aviso");
- **dónde** queda registrada (en el PR, con enlace al riesgo aceptado);
- **cuándo** se revisa de nuevo.

## 3. El gate en el pipeline

```yaml
security-gate:
  needs: [secrets, build, sast, sca, container, iac]
  if: always()
  steps:
    - name: Evaluar el resultado de todos los controles
      run: |
        if [ "${{ contains(needs.*.result, 'failure') }}" = "true" ]; then
          echo "SECURITY GATE: FAILED"
          exit 1
        fi
```

Nota el `if: always()`. Si no estuviera, el gate se saltaría justo cuando algún
control falla: el peor momento posible para no evaluar nada.

## 4. La demo: el pipeline fallando

Este es el momento más importante del taller.

```
BUILD                       ✅
UNIT TESTS                  ✅
SECRET SCANNING             ✅
SAST                        ✅
DEPENDENCY SCAN             ❌  HIGH vulnerability detected (CVE-2024-21907)
CONTAINER SCAN              ❌  CRITICAL vulnerabilities in base image
IaC SCAN                    ❌  privileged container

SECURITY GATE: FAILED
```

Pausa. Y luego:

> **Este FAIL es algo bueno.**

El pipeline acaba de evitar que una vulnerabilidad conocida llegue a producción.
No se rompió el proceso: el proceso hizo su trabajo. Un pipeline que nunca falla
por seguridad no es un pipeline seguro; es un pipeline que no está mirando.

## 5. Lo que hay que evitar

| Anti-patrón | Qué pasa después |
|---|---|
| `continue-on-error: true` en todo | el gate es decorativo |
| Umbral tan alto que nunca falla | nadie mira los resultados |
| Umbral tan bajo que siempre falla | el equipo aprende a ignorarlo |
| Sin proceso de excepción | la gente desactiva el escaneo |
| Hallazgos sin dueño | nadie los arregla nunca |

## 6. Ejercicio

En `ci-devsecops.yml`, cambia:

```yaml
GATE_SEVERITY: "HIGH,CRITICAL"
```

por:

```yaml
GATE_SEVERITY: "CRITICAL"
```

Pregunta: ¿qué deja de bloquear? ¿Es aceptable para SecureHR? ¿Por qué sí o por
qué no?

No hay respuesta correcta. Hay una respuesta **documentada** y otra que no.

## Cierre

Casilla del día: **Security gates ✅** — 6 de 6.

> Un gate no es un número. Es una política que alguien firmó.
