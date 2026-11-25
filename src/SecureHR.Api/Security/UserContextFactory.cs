using System.Security.Claims;
using SecureHR.Api.Models;

namespace SecureHR.Api.Security;

public static class UserContextFactory
{
    public static UserContext From(ClaimsPrincipal? principal)
    {
        if (principal?.Identity?.IsAuthenticated != true)
        {
            return new UserContext();
        }

        return new UserContext
        {
            UserId = principal.Identity.Name ?? "unknown",
            Role = principal.FindFirst(ClaimTypes.Role)?.Value ?? "Employee",
            Department = principal.FindFirst("department")?.Value ?? string.Empty,
            EmployeeId = int.TryParse(principal.FindFirst("employee_id")?.Value, out var id) ? id : 0
        };
    }
}
