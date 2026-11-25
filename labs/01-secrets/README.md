# Laboratorio 1 · El secreto a plena vista

**Tiempo:** 15 minutos · **Herramienta:** Gitleaks · **Control:** Secret Scanning

---

## Objetivo

Descubrir que en el repositorio hay credenciales reales de producción y que
ningún control del pipeline actual lo detectó.

## 1. Busca el problema (3 minutos, sin herramientas)

Abre `src/SecureHR.Api/appsettings.Development.json`.

```json
"ConnectionStrings": {
  "Database": "Host=db.securehr.internal;Port=5432;Database=securehr;Username=admin;Password=HR20**!"
},
"PayrollApiKey": "demo-payroll-key-*****"
```

Preguntas para el grupo:

- ¿Alguien del equipo sabía que esa contraseña está aquí? (Normalmente: no.)
- ¿Quién puede leer este archivo? (Cualquiera con acceso al repositorio… y el
  repositorio tiene 400 personas con acceso, y un espejo en un servidor de CI.)
- ¿Esta contraseña existe en producción? (Si el archivo se copió a producción
  alguna vez, sí. Y no la vamos a cambiar por el taller.)

Ese último punto es la clave: **un secreto publicado es un secreto comprometido,
aunque lo borres mañana.**

## 2. Encuéntralo como lo haría un pipeline

```powershell
# Windows
.\scripts\scan.ps1 secrets
```

```bash
# Linux / macOS / Codespaces
bash scripts/scan.sh secrets
```

Salida esperada (resumida):

```
Finding:     Password=HR20**!
RuleID:      securehr-connection-string
File:        src/SecureHR.Api/appsettings.Development.json
Line:        8

Finding:     demo-payroll-key-*****
RuleID:      securehr-payroll-api-key
File:        src/SecureHR.Api/appsettings.Development.json
Line:        9
```

Exit code `1`. **Ese 1 es el control funcionando.**

> Gitleaks está configurado con reglas propias en `.gitleaks.toml`. Léelo: son
> 10 líneas y explican exactamente qué se considera un secreto en SecureHR.
> Esa es la conversación importante: una herramienta sin reglas del negocio es
> solo un linter.

## 3. La conversación de escala

Todos vimos el secreto en 30 segundos. Ahora la pregunta incómoda:

> ¿Y si tenemos 30 repositorios y 400 desarrolladores?

Lo que acaba de pasar fue una **revisión manual**. La revisión manual no escala,
no es consistente y depende de que alguien se acuerde. Un guardrail sí escala:

```
Revisión manual            Guardrail automático
  depende de memoria   →     se ejecuta siempre
  se olvida            →     no se olvida
  no deja registro     →     deja evidencia
```

## 4. Qué hacer además de detectar

Detectar no es arreglar. El orden importa:

1. **Rotar la credencial.** Ya está comprometida. Cambiarla es lo primero.
2. **Sacarla del código.** Variables de entorno, user-secrets, Vault, Key Vault.
3. **Limpiar el historial.** `git filter-repo` o BFG. El secreto sigue en los
   commits viejos aunque borres el archivo.
4. **Poner el guardrail.** Pre-commit hook + job en CI (lo hacemos en el Lab 6).

## 5. Cierre

Casilla del día: **Secret scanning ✅**

Frase para llevarse:

> Un secreto en el repositorio no es un problema de configuración.
> Es una credencial comprometida con fecha y hora.

## Comandos de referencia

```bash
# Escanear el histórico completo de git (más lento, más completo)
gitleaks detect -s . -c .gitleaks.toml --redact -v

# Escanear solo el directorio actual
gitleaks detect -s . -c .gitleaks.toml --no-git --redact -v

# Escanear antes de hacer commit
gitleaks protect --staged -c .gitleaks.toml -v
```
