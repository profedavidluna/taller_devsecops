using Microsoft.AspNetCore.Authentication;
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
