using SecureHR.Api.Models;

namespace SecureHR.Api.Security;

/// <summary>
/// Regla de negocio: ¿quién puede consultar el registro de qué empleado?
///
/// Esta clase SÍ está implementada y SÍ tiene pruebas en verde.
/// El problema del laboratorio es que el controlador no la invoca.
/// Una regla que no se aplica no protege nada.
/// </summary>
public sealed class EmployeeAccessPolicy
{
    public bool CanRead(UserContext user, Employee employee)
    {
        if (user is null || employee is null)
        {
            return false;
        }

        if (string.IsNullOrEmpty(user.UserId) || user.IsInRole("None"))
        {
            return false;
        }

        // Nómina y administración gestionan toda la plantilla.
        if (user.IsInRole("Admin") || user.IsInRole("Payroll"))
        {
            return true;
        }

        // Un jefe de área ve a su equipo.
        if (user.IsInRole("Manager"))
        {
            return string.Equals(user.Department, employee.Department, StringComparison.OrdinalIgnoreCase);
        }

        // Cualquier otra persona solo ve su propio registro.
        return employee.Id == user.EmployeeId;
    }
}
