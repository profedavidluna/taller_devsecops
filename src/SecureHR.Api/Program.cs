using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.DataProtection;
using SecureHR.Api.Security;
using SecureHR.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddSingleton<EmployeeRepository>();
builder.Services.AddSingleton<AuditLogger>();
builder.Services.AddSingleton<ReportService>();
builder.Services.AddSingleton<EmployeeAccessPolicy>();

builder.Services
    .AddAuthentication(HeaderAuthenticationHandler.SchemeName)
    .AddScheme<AuthenticationSchemeOptions, HeaderAuthenticationHandler>(
        HeaderAuthenticationHandler.SchemeName, _ => { });

builder.Services.AddAuthorization();

// Data Protection guarda sus claves en el perfil del usuario
// (%LOCALAPPDATA%\ASP.NET\DataProtection-Keys). En portátiles con el perfil
// redirigido —o sin permiso de escritura ahí— la aplicación arranca con un
// error en rojo que no aporta nada al taller. Las claves van a una carpeta
// temporal: esta API no usa cookies ni antiforgery, así que no necesitamos que
// sobrevivan a un reinicio.
var dataProtectionKeys = Path.Combine(Path.GetTempPath(), "securehr-dataprotection");
Directory.CreateDirectory(dataProtectionKeys);
builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(dataProtectionKeys))
    .SetApplicationName("SecureHR");

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        // "Lo abrimos para que el front-end de Recursos Humanos pueda consumir
        // la API sin configurar los orígenes" — decisión original del equipo.
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});

var app = builder.Build();

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "securehr-api" }));

app.MapGet("/whoami", (System.Security.Claims.ClaimsPrincipal user) =>
{
    var ctx = UserContextFactory.From(user);
    return Results.Ok(new { ctx.UserId, ctx.Role, ctx.Department, ctx.EmployeeId });
}).RequireAuthorization();

app.MapControllers();

app.Run();
