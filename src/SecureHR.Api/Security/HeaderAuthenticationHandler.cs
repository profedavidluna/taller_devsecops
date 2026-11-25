using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace SecureHR.Api.Security;

/// <summary>
/// Autenticación de demostración: en producción esto sería un JWT emitido por
/// el proveedor de identidad corporativo. Para el laboratorio usamos cabeceras
/// para no perder tiempo configurando un IdP.
/// </summary>
public sealed class HeaderAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "DemoHeader";

    public HeaderAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue("X-Demo-User", out var userHeader) ||
            string.IsNullOrWhiteSpace(userHeader))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var role = Request.Headers["X-Demo-Role"].FirstOrDefault() ?? "Employee";
        var department = Request.Headers["X-Demo-Department"].FirstOrDefault() ?? string.Empty;
        var employeeId = Request.Headers["X-Demo-EmployeeId"].FirstOrDefault() ?? "0";

        var claims = new List<Claim>
        {
            new(ClaimTypes.Name, userHeader.ToString()),
            new(ClaimTypes.Role, role),
            new("department", department),
            new("employee_id", employeeId)
        };

        var identity = new ClaimsIdentity(claims, SchemeName);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, SchemeName);

        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
