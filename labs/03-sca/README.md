# Laboratorio 3 · Nuestro código está bien… la librería no

**Tiempo:** 20 minutos · **Herramienta:** Trivy (fs) · **Control:** SCA

---

## Objetivo

Descubrir que una parte del software que ejecutamos no lo escribimos nosotros, y
que una dependencia vieja es una vulnerabilidad heredada.

## 1. La pregunta

> ¿Quién escribió esta vulnerabilidad?

Nadie del equipo. Nadie del área. Está en el código de un tercero que
instalamos con una línea en el `.csproj`.

## 2. Encuéntrala

```powershell
.\scripts\scan.ps1 sca
```

```bash
bash scripts/scan.sh sca
```

Salida esperada (resumida):

```
src/SecureHR.Api/packages.lock.json (nuget)

Total: 1 (HIGH: 1, CRITICAL: 0)

┌─────────────────┬────────────────┬──────────┬────────┬───────────────────┐
│     Library     │ Vulnerability  │ Severity │ Status │ Installed Version │
├─────────────────┼────────────────┼──────────┼────────┼───────────────────┤
│ Newtonsoft.Json │ CVE-2024-21907 │ HIGH     │ fixed  │ 12.0.1            │
└─────────────────┴────────────────┴──────────┴────────┴───────────────────┘
```

La vulnerabilidad es una **denegación de servicio** al deserializar JSON
malformado. `AuditLogger` serializa eventos en cada request: el vector está
conectado con la aplicación.

> Trivy lee `packages.lock.json`. Si no existe ese archivo, el escaneo de NuGet
> puede no ver nada. Por eso el proyecto tiene `RestorePackagesWithLockFile`.

## 3. Por qué esto es distinto a un bug normal

```
Tu aplicación
├── 10 % código que escribiste (y que revisaste)
└── 90 % código que no escribiste (frameworks, dependencias, transitivas)
```

No puedes arreglar el bug. No tienes el código. Lo único que puedes hacer es
**actualizar**. Y para actualizar hay que enterarse primero.

Ahí entra la **cadena de suministro de software** (*software supply chain*):

- ¿Qué versión tenemos? (inventario / SBOM)
- ¿Tiene vulnerabilidades conocidas? (SCA)
- ¿Está la actualización disponible? (¿y rompe algo?)
- ¿Quién la aprobó y cuándo? (trazabilidad)

## 4. Arreglo (2 minutos)

```powershell
.\scripts\apply-fix.ps1 -Lab 3
```

```bash
bash scripts/apply-fix.sh 3
```

El cambio completo es:

```diff
-    <PackageReference Include="Newtonsoft.Json" Version="12.0.1" />
+    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
```

Ni un `if` cambió. La vulnerabilidad desapareció.

Vuelve a escanear: `exit 0`.

## 5. La parte que no es cómoda

Actualizar no siempre es gratis:

- puede romper compatibilidad;
- puede arrastrar otras dependencias;
- puede requerir ventana de mantenimiento.

Por eso el SCA no se inventó para *prohibir*, sino para **decidir con datos**:

| Pregunta | Dato que necesitas |
|---|---|
| ¿Estamos expuestos? | ¿La ruta vulnerable se usa en nuestro código? |
| ¿Hay fix? | versión con parche disponible |
| ¿Cuánto riesgo? | severidad + criticidad del servicio + datos que toca |

## 6. Bonus: la vista nativa del ecosistema

```bash
dotnet list package --vulnerable --include-transitive
```

Misma información, otra puerta. En el pipeline usamos Trivy porque además
escanea imagen, sistema operativo y configuración con el mismo comando base.

## Cierre

Casilla del día: **SCA ✅**

> El código que escribimos es nuestro. El código que ejecutamos también.
