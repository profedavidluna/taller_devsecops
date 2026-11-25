# Laboratorio 6 · Construir el pipeline DevSecOps

**Tiempo:** 15 minutos · **Archivo:** `.github/workflows/ci-devsecops.yml`

---

## Objetivo

Convertir el pipeline en un sistema con controles, en el orden correcto y con
las dependencias correctas. Este bloque se construye **en voz alta con el
público**: ellos dicen qué falta, tú lo ubicas en el diagrama.

## 1. Antes

```yaml
jobs:
  build-and-deploy:
    steps:
      - checkout
      - restore
      - build
      - test
      - docker build
      - deploy
```

Cuatro verdes y un despliegue. Ninguna pregunta de seguridad.

## 2. La pregunta que abre el bloque

> Después de todo lo que vimos, **¿qué falta?**

Ve anotando lo que digan y ordénalo en el diagrama:

```
                    PUSH
                      │
                      ▼
              Secret scanning   ← antes de construir nada
                      │
                      ▼
                    BUILD
                      │
            ┌─────────┴─────────┐
            ▼                   ▼
           SAST                SCA          ← en paralelo, no en serie
            └─────────┬─────────┘
                      ▼
                    TEST
                      │
                      ▼
               Docker build
                      │
                      ▼
              Container scan
                      │
                      ▼
                  IaC scan
                      │
                      ▼
               SECURITY GATE
                ┌─────┴─────┐
                ▼           ▼
              PASS         FAIL
                │           │
                ▼           ▼
             DEPLOY      BLOCK + avisar al autor del PR
```

## 3. Por qué el orden importa

| Control | Cuándo | Razón |
|---|---|---|
| Secret scanning | primero | es lo más barato y lo más grave |
| Build + tests | después | no tiene sentido analizar código que no compila |
| SAST + SCA | en paralelo | son independientes; en serie solo pierdes tiempo |
| Container scan | tras `docker build` | necesitas la imagen para escanearla |
| IaC scan | junto al código | el manifiesto se revisa en el mismo PR |
| Gate | al final | una sola decisión, con toda la evidencia |

**Regla práctica:** el feedback más rápido va primero. Un pipeline de 20 minutos
que nadie mira es peor que uno de 4 minutos que todos respetan.

## 4. Ábrelo y recórrelo

```bash
code .github/workflows/ci-devsecops.yml
```

Puntos que hay que señalar en vivo:

1. **Cada job usa la misma herramienta que corriste localmente.** Si no se
   reproduce en tu máquina, no es un control, es una caja negra.
2. **`needs:`** modela las dependencias reales, y eso hace que el grafo del
   pipeline sea visible en la UI de GitHub.
3. **`container` necesita el `docker build`**, por eso depende de `build`.
4. **El gate es un job aparte** con `if: always()`: se ejecuta aunque algún
   control falle, porque su trabajo es exactamente evaluar eso.

## 5. Probar el pipeline sin push (recomendado para el taller)

Los jobs son comandos. Puedes ejecutar la secuencia completa localmente:

```powershell
.\scripts\scan.ps1 all
```

```bash
bash scripts/scan.sh all
```

Si los cinco comandos se comportan igual que en CI, el pipeline es reproducible,
y eso es la mitad del valor.

## 6. Actividad (5 minutos, en parejas)

Cada pareja elige **un** control y responde:

- ¿Qué pregunta de seguridad responde?
- ¿Qué falso positivo produce?
- ¿Qué harías con un hallazgo que no puedes arreglar hoy?

La tercera pregunta es la que genera la conversación más útil: el proceso de
excepción. Sin él, el equipo aprende a desactivar el escaneo.

## Cierre

Casillas del día: **5 de 6** ✅

Falta la más política de todas: **Security Gates** (Laboratorio 7).
