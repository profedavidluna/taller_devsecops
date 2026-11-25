# syntax=docker/dockerfile:1
#
# Dockerfile INSEGURO — es el punto de partida del Laboratorio 4.
# Funciona. La aplicación arranca. Y arrastra todo esto:
#
#   1. Etapa única implícita: se copia el contexto completo (tests, .git, config).
#   2. Imagen base completa (no chiseled): cientos de paquetes que no usamos.
#   3. Corre como root (no hay USER).
#   4. chmod -R 777 "para que no falle en el servidor de pruebas".
#   5. Los appsettings de Development viajan dentro de la imagen,
#      incluida la contraseña de la base y la API key de nómina.
#
# No lo arregles todavía: primero mídelo (Lab 4).

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish "src/SecureHR.Api/SecureHR.Api.csproj" -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .

# "En el servidor de pruebas daba errores de permisos y esto lo resolvió"
RUN chmod -R 777 /app

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "SecureHR.Api.dll"]
