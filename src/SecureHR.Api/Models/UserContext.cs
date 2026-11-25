namespace SecureHR.Api.Models;

/// <summary>
/// Identidad mínima del solicitante, construida a partir del token/claims.
/// </summary>
public sealed class UserContext
{
    public string UserId { get; init; } = "anonymous";
    public string Role { get; init; } = "None";
    public string Department { get; init; } = string.Empty;
    public int EmployeeId { get; init; }

    public bool IsInRole(string role) =>
        string.Equals(Role, role, StringComparison.OrdinalIgnoreCase);
}
