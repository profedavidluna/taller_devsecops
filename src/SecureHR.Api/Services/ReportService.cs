using SecureHR.Api.Models;

namespace SecureHR.Api.Services;

/// <summary>
/// Servicio de reportes heredado del equipo de BI.
///
/// MOTOR SIMULADO: en producción esta clase ejecuta la sentencia contra
/// PostgreSQL. En el laboratorio no hay base de datos, así que devolvemos la
/// sentencia generada y simulamos cuántas filas devolvería el motor real.
/// </summary>
public sealed class ReportService
{
    private readonly EmployeeRepository _repository;
    private readonly AuditLogger _audit;

    public ReportService(EmployeeRepository repository, AuditLogger audit)
    {
        _repository = repository;
        _audit = audit;
    }

    public ReportPreview Run(string sql, string department)
    {
        _audit.Log("report.execute", new { sql, department });

        // Simulación del comportamiento del motor ante una tautología:
        // si la cláusula WHERE se rompe, el motor devuelve TODA la tabla.
        var injectionDetected =
            sql.Contains("' OR '", StringComparison.OrdinalIgnoreCase) ||
            sql.Contains("'OR'", StringComparison.OrdinalIgnoreCase) ||
            sql.Contains("OR 1=1", StringComparison.OrdinalIgnoreCase);

        var rows = injectionDetected
            ? _repository.All().Count
            : _repository.ByDepartment(department).Count;

        return new ReportPreview(sql, rows, "postgres://securehr (motor simulado en laboratorio)");
    }
}
