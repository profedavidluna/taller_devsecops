using SecureHR.Api.Models;
using SecureHR.Api.Security;
using Xunit;

namespace SecureHR.Tests;

/// <summary>
/// Estas pruebas están en VERDE desde el minuto cero del taller.
///
/// Demuestran que "tener pruebas automatizadas" no es lo mismo que "estar
/// protegido": la política de acceso funciona, pero el controlador no la usa.
/// </summary>
public sealed class EmployeeAccessPolicyTests
{
    private readonly EmployeeAccessPolicy _policy = new();

    private static readonly Employee FinanceEmployee = new()
    {
        Id = 3, FullName = "María Fernández", Department = "Finance", Salary = 5100m
    };

    private static readonly Employee EngineeringEmployee = new()
    {
        Id = 7, FullName = "John Doe", Department = "Engineering", Salary = 2800m
    };

    [Fact]
    public void Payroll_puede_leer_cualquier_registro()
    {
        var user = new UserContext { UserId = "payroll.svc", Role = "Payroll", Department = "Finance" };

        Assert.True(_policy.CanRead(user, EngineeringEmployee));
    }

    [Fact]
    public void Admin_puede_leer_cualquier_registro()
    {
        var user = new UserContext { UserId = "admin", Role = "Admin", Department = "Operations" };

        Assert.True(_policy.CanRead(user, FinanceEmployee));
    }

    [Fact]
    public void Manager_puede_leer_solo_su_departamento()
    {
        var user = new UserContext { UserId = "carlos", Role = "Manager", Department = "Engineering", EmployeeId = 2 };

        Assert.True(_policy.CanRead(user, EngineeringEmployee));
        Assert.False(_policy.CanRead(user, FinanceEmployee));
    }

    [Fact]
    public void Empleado_puede_leer_su_propio_registro()
    {
        var user = new UserContext { UserId = "john", Role = "Employee", Department = "Engineering", EmployeeId = 7 };

        Assert.True(_policy.CanRead(user, EngineeringEmployee));
    }

    [Fact]
    public void Empleado_no_puede_leer_el_registro_de_otra_persona()
    {
        var user = new UserContext { UserId = "john", Role = "Employee", Department = "Engineering", EmployeeId = 7 };

        Assert.False(_policy.CanRead(user, FinanceEmployee));
    }

    [Fact]
    public void Usuario_anonimo_no_puede_leer_nada()
    {
        Assert.False(_policy.CanRead(new UserContext(), FinanceEmployee));
    }

    [Fact]
    public void Politica_rechaza_argumentos_nulos()
    {
        Assert.False(_policy.CanRead(null!, FinanceEmployee));
        Assert.False(_policy.CanRead(new UserContext { UserId = "x", Role = "Admin" }, null!));
    }
}
