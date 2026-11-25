using SecureHR.Api.Services;
using Xunit;

namespace SecureHR.Tests;

public sealed class ReportServiceTests
{
    private static ReportService BuildService() =>
        new(new EmployeeRepository(), new AuditLogger());

    [Fact]
    public void Reporte_filtrado_devuelve_solo_el_departamento_pedido()
    {
        var service = BuildService();
        var sql = "SELECT id FROM employees WHERE department = 'Finance'";

        var result = service.Run(sql, "Finance");

        Assert.Equal(3, result.RowsReturned);
        Assert.Contains("Finance", result.Sql);
    }

    [Fact]
    public void Motor_simulado_devuelve_toda_la_tabla_si_la_clausula_se_rompe()
    {
        var service = BuildService();
        var sql = "SELECT id FROM employees WHERE department = 'Finance' OR '1'='1'";

        var result = service.Run(sql, "Finance");

        // Ninguna prueba falla: el comportamiento es "el esperado" por el motor.
        // El problema no es un bug funcional, es un problema de seguridad.
        Assert.Equal(12, result.RowsReturned);
    }
}
