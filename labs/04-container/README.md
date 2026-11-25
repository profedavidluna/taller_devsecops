# Laboratorio 4 · El Dockerfile que funciona perfectamente

**Tiempo:** 15 minutos · **Herramienta:** Trivy (image) · **Control:** Container Scanning

---

## Objetivo

Ver que la imagen es parte de la aplicación: tiene vulnerabilidades, permisos y
secretos propios, y nadie las revisa porque "el contenedor funciona".

## 1. Lee el Dockerfile

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
RUN chmod -R 777 /app
```

Pregunta al grupo: **¿qué problemas ven?** Suelen aparecer estos:

| Punto | Por qué importa |
|---|---|
| Imagen base completa | cientos de paquetes que no usas, cada uno con sus CVEs |
| Sin `USER` | el proceso corre como root |
| `chmod -R 777` | cualquier proceso comprometido escribe y ejecuta en /app |
| `COPY` del contexto | tests, configuración y secretos viajan dentro |
| Sin `HEALTHCHECK` | el orquestador no sabe si está sano |

## 2. Mídelo

Construye y escanea:

```powershell
.\scripts\scan.ps1 image
```

```bash
bash scripts/scan.sh image
```

Salida esperada (las cifras varían con la fecha de la base de datos):

```
securehr:latest (debian 12.x)

Total: 42 (HIGH: 14, CRITICAL: 3)

┌──────────────────┬────────────────┬──────────┬───────────────────┐
│     Library      │ Vulnerability  │ Severity │ Installed Version │
├──────────────────┼────────────────┼──────────┼───────────────────┤
│ libssl3          │ CVE-2024-XXXXX │ CRITICAL │ 3.0.x             │
│ zlib1g           │ CVE-2023-XXXXX │ HIGH     │ 1:1.2.13          │
│ ...              │                │          │                   │
└──────────────────┴────────────────┴──────────┴───────────────────┘
```

Dos cosas que hay que decir aquí:

1. **La mayoría de esos CVEs no son de tu código.** Son del sistema operativo
   base. Tú no los introdujiste; los heredaste al elegir la imagen.
2. **Ninguno aparece en `dotnet test`.** Todos tus tests están verdes.

## 3. Los secretos también viajan

Esto es lo que de verdad impresiona en el taller:

```bash
docker run --rm --entrypoint sh securehr:latest \
  -c "cat /app/appsettings.Development.json"
```

```powershell
docker run --rm --entrypoint sh securehr:latest `
  -c "cat /app/appsettings.Development.json"
```

Ahí está la contraseña de la base y la API key de nómina, dentro de una imagen
que se publica en un registry. Cualquiera que pueda hacer `docker pull` las
tiene. Y las capas no se borran: si mañana la quitas, sigue en el historial.

```bash
# ¿Quién soy dentro del contenedor?
docker run --rm --entrypoint whoami securehr:latest
# => root
```

## 4. Arreglo

```powershell
.\scripts\apply-fix.ps1 -Lab 4
```

```bash
bash scripts/apply-fix.sh 4
```

El `Dockerfile` pasa a:

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0-jammy-chiseled
WORKDIR /app
COPY --from=build /app .
USER $APP_UID
```

- **multi-stage con caché**: `restore` antes de copiar el código;
- **solo el artefacto**: ni tests, ni repositorio, ni configuración de desarrollo;
- **chiseled**: sin shell, sin gestor de paquetes, superficie mínima;
- **no root**: `$APP_UID` (1654) ya existe en la imagen.

```bash
docker build -f Dockerfile -t securehr:secure .
docker run --rm --entrypoint whoami securehr:secure
# => app
```

Y el conteo de CVEs baja de decenas a un puñado.

> No se trata de llegar a cero. Se trata de que las cifras sean una decisión y
> no una sorpresa.

## 5. El mensaje

La imagen no es "el empaque". Es una parte de tu aplicación que se ejecuta en
producción, con sus propios paquetes, sus propios usuarios y sus propios
permisos. Si no la escaneas, estás desplegando código que nunca revisaste.

## Cierre

Casilla del día: **Container scanning ✅**

> `docker build` correcto no significa `docker image` seguro.
