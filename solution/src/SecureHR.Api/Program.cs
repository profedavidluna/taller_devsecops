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

// CORS: lista explícita. Si un origen no está aquí, no hay llamada desde el navegador.
var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? new[] { "https://rrhh.securehr.internal" };

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod();
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
