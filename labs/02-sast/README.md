# Laboratorio 2 · "El endpoint funciona"

**Tiempo:** 20 minutos · **Herramienta:** Semgrep · **Control:** SAST + Secure Coding

---

## Objetivo

Entender la diferencia entre autenticación y autorización, ver un caso real de
*Broken Access Control* (BOLA/IDOR) y comprobar que un SAST **no** lo encuentra.

## 1. Levanta la API

```bash
dotnet run --project src/SecureHR.Api
```

La API escucha en `http://localhost:5080`. La autenticación del laboratorio es
simulada con cabeceras (en producción sería un JWT del proveedor de identidad).

## 2. El experimento

Eres **John Doe**, desarrollador junior (empleado 7, departamento Engineering).
Pide tu propia ficha:

```powershell
$john = @{ 'X-Demo-User'='john.doe'; 'X-Demo-Role'='Employee';
           'X-Demo-Department'='Engineering'; 'X-Demo-EmployeeId'='7' }
Invoke-RestMethod http://localhost:5080/employees/7 -Headers $john
```

```bash
curl -s http://localhost:5080/employees/7 \
  -H "X-Demo-User: john.doe" -H "X-Demo-Role: Employee" \
  -H "X-Demo-Department: Engineering" -H "X-Demo-EmployeeId: 7"
```

Correcto. Ahora pide la ficha de la empleada 3, que está en **Finance**:

```powershell
Invoke-RestMethod http://localhost:5080/employees/3 -Headers $john
```

```bash
curl -s http://localhost:5080/employees/3 \
  -H "X-Demo-User: john.doe" -H "X-Demo-Role: Employee" \
  -H "X-Demo-Department: Engineering" -H "X-Demo-EmployeeId: 7"
```

**HTTP 200.** Con nombre completo, correo, puesto, **salario** y **cédula**.

Nadie hackeó nada. Se cambió un número en la URL.

## 3. Qué está mal (y qué no)

```
[Authorize]                    → ¿quién eres?         ✅ funciona
[Authorize(Roles="Payroll")]   → ¿qué rol tienes?     ✅ funciona
la regla de negocio            → ¿puedes ver ESTE?    ❌ no existe
```

`EmployeeAccessPolicy` existe, está implementada y **tiene 7 pruebas en verde**
(`dotnet test`). El controlador simplemente no la llama.

> 7 tests verdes, build verde, cobertura decente.
> Y la aplicación filtra salarios de toda la plantilla.

## 4. El mini desafío

¿Cuál de estas tres líneas garantiza que este usuario puede ver este registro?

```csharp
// A
[Authorize]
GET /employees/{id}

// B
SELECT * FROM employees WHERE id = @id

// C
logger.LogInformation("Employee {Id} retrieved by {User}", id, userId);
```

**Ninguna.** `[Authorize]` dice que hay un usuario. El `WHERE id = @id` dice qué
fila quieres. El log dice que pasó. Ninguna dice si *tú* deberías verla.

La autorización es una **regla de negocio**. Y las reglas de negocio no salen de
un framework: salen de una decisión de diseño.

## 5. Ahora sí, SAST

```powershell
.\scripts\scan.ps1 sast
```

```bash
bash scripts/scan.sh sast
```

Semgrep reporta **3 hallazgos**:

| Regla | Archivo | Severidad |
|---|---|---|
| `securehr-sql-string-interpolation` | `ReportsController.cs` | ERROR |
| `securehr-cors-allow-any-origin` | `Program.cs` | WARNING |
| `securehr-exception-details-leaked` | `EmployeesController.cs` | WARNING |

Ejemplo:

```
Controllers/ReportsController.cs
  34┆ var sql = $"SELECT id, full_name, salary FROM employees WHERE department = '{department}'";
  ❯❯❱ securehr-sql-string-interpolation
          Consulta SQL construida con interpolación de cadenas...
```

### El detalle que hay que subrayar

Semgrep encontró **tres** problemas de código.
Semgrep **no** encontró el BOLA.

Y no es un defecto de Semgrep: es una ausencia en el modelo de autorización, no
un patrón sintáctico. Un SAST lee el código; no lee la intención.

```
Automation  +  Conocimiento del desarrollador  +  Diseño de seguridad
      ↑                    ↑                              ↑
   Semgrep            code review                   threat modeling
```

## 6. Arreglo

```powershell
.\scripts\apply-fix.ps1 -Lab 2
```

```bash
bash scripts/apply-fix.sh 2
```

Ahora:

```bash
# john -> su ficha            => 200
# john -> ficha de Finance    => 403
# payroll -> cualquier ficha  => 200
# manager de Engineering -> Finance => 403
```

Y el CORS deja de aceptar `https://evil.example`.

## Cierre

Casilla del día: **SAST ✅** y, sobre todo, **criterio de diseño ✅**

> La herramienta te dice dónde mirar. No te dice qué debería estar pasando.
