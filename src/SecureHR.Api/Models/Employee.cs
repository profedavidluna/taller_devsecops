namespace SecureHR.Api.Models;

/// <summary>
/// Registro de empleado tal como lo consume el área de Recursos Humanos.
/// Contiene datos personales y salariales: es información sensible.
/// </summary>
public sealed class Employee
{
    public int Id { get; init; }
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Department { get; init; } = string.Empty;
    public string Position { get; init; } = string.Empty;
    public decimal Salary { get; init; }
    public string NationalId { get; init; } = string.Empty;
}
