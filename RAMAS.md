# Ramas de la solución

Este repositorio tiene **una rama por paso de la solución**, acumulativas: cada
una parte de la anterior y añade el arreglo de un laboratorio.

`main` es el punto de partida: la aplicación funciona, el pipeline está verde y
no hay ningún control de seguridad.

| Rama | Añade | Controles instalados |
|---|---|---|
| `main` | — | 0 / 6 |
| [`lab-01-secrets`](../../tree/lab-01-secrets) | Credenciales fuera del repositorio | 1 / 6 |
| [`lab-02-sast`](../../tree/lab-02-sast) | Autorización por objeto + CORS cerrado | 2 / 6 |
| [`lab-03-sca`](../../tree/lab-03-sca) | Dependencia vulnerable actualizada | 3 / 6 |
| [`lab-04-container`](../../tree/lab-04-container) | Imagen multi-stage, chiseled y sin root | 4 / 6 |
| [`lab-05-iac`](../../tree/lab-05-iac) | Pod sin privilegios + infraestructura cerrada | 5 / 6 |
| [`lab-06-pipeline`](../../tree/lab-06-pipeline) | Pipeline con los seis escaneos, sin gate | 5 / 6 |
| [`lab-07-gates`](../../tree/lab-07-gates) | Security gate + política de severidades | 6 / 6 |

## Cómo usarlas en el taller

```bash
# Empezar el laboratorio 3 con los labs 1 y 2 ya resueltos
git checkout lab-02-sast

# Ver el resultado final
git checkout lab-07-gates

# Comparar exactamente lo que añade un paso
git diff lab-02-sast..lab-03-sca

# Volver al estado inicial (vulnerable)
git checkout main
```

Cada rama tiene **un solo commit** encima de la anterior: el diff de la rama es
literalmente el cambio que se explica en el laboratorio.

## Reglas

- `main` no se modifica: es el punto de partida del taller y debe seguir siendo
  vulnerable.
- Las ramas publicadas no se reescriben. Si hay que corregir algo, se añade un
  commit nuevo.
- El secreto de `main` es ficticio y el repositorio es material didáctico. Aun
  así, en un proyecto real **rotar la credencial es siempre el primer paso**, no
  el último.

## Relación con el material

- La guía paso a paso de cada laboratorio está en `labs/01-secrets` …
  `labs/08-solution`.
- Los archivos ya corregidos, sueltos, están en `solution/`.
- `scripts/apply-fix.ps1 -Lab N` aplica la misma corrección sobre `main` sin
  cambiar de rama, para quien se quedó atrás en la sala.
