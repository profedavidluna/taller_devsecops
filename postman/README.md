# Colección de Postman

Tres carpetas, doce peticiones, todas con pruebas automáticas. Sirve para
probar la API sin escribir `curl` a mano.

## Importar

**Opción rápida (sin descargar nada):**

1. Abre Postman → **Import** → pestaña **Link**.
2. Pega:
   `https://raw.githubusercontent.com/profedavidluna/taller_devsecops/main/postman/SecureHR.postman_collection.json`
3. Import.

**Opción local** (si ya tienes el repositorio):

1. Postman → **Import** → **Files**.
2. Selecciona `SecureHR.postman_collection.json` (y, si quieres, el environment).

## Antes de ejecutar

La API tiene que estar corriendo:

```bash
dotnet run --project src/SecureHR.Api
```

Y la variable `baseUrl` debe apuntar a donde escucha:

- En tu máquina: `http://localhost:5080` (valor por defecto).
- En Codespaces: abre la pestaña **Ports**, copia la URL del puerto 5080 y
  pégala en la variable `baseUrl` de la colección.

## Qué contiene

| Carpeta | Peticiones | Para qué |
|---|---|---|
| `00 · Salud y contexto` | 4 | Comprobar que la API responde y que la autenticación con cabeceras funciona |
| `01 · Empleados · el BOLA` | 5 | El corazón del Lab 2: `1.2` devuelve 200 con el salario de otra persona |
| `02 · Reportes · inyección` | 3 | `2.2` rompe la cláusula WHERE y devuelve toda la tabla |

## Cómo leer el resultado

El código de estado **es** el resultado del laboratorio:

- `1.2` y `1.4` → **200** en la aplicación sin arreglar, **403** después de
  `apply-fix -Lab 2`. Ese cambio es el que hay que ver.
- `0.4` → 401 y `2.3` → 403 confirman que autenticación y roles sí funcionan.
  Lo que falta es la autorización por objeto.

Si ejecutas la colección completa con el **Collection Runner** verás el resumen
de las doce peticiones de una vez, que es la forma más rápida de comprobar el
estado del repositorio en el que estás.
