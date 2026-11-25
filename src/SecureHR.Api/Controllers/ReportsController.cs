using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SecureHR.Api.Models;
using SecureHR.Api.Services;

namespace SecureHR.Api.Controllers;

[ApiController]
[Route("reports")]
[Authorize(Roles = "Payroll,Admin")]
public sealed class ReportsController : ControllerBase
{
    private readonly ReportService _reports;

    public ReportsController(ReportService reports)
    {
        _reports = reports;
    }

    /// <summary>
    /// Reporte de personal por departamento, usado por Nómina.
    /// Construye la sentencia concatenando la entrada del usuario.
    /// </summary>
    [HttpGet("employees-by-department")]
    public ActionResult<ReportPreview> EmployeesByDepartment([FromQuery] string department)
    {
        if (string.IsNullOrWhiteSpace(department))
        {
            return BadRequest(new { message = "El parámetro 'department' es obligatorio." });
        }

        var sql = $"SELECT id, full_name, salary FROM employees WHERE department = '{department}'";

        var result = _reports.Run(sql, department);
        return Ok(result);
    }
}
