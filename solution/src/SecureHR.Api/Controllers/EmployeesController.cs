using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SecureHR.Api.Models;
using SecureHR.Api.Security;
using SecureHR.Api.Services;

namespace SecureHR.Api.Controllers;

[ApiController]
[Route("employees")]
[Authorize]
public sealed class EmployeesController : ControllerBase
{
    private readonly EmployeeRepository _repository;
    private readonly EmployeeAccessPolicy _accessPolicy;
    private readonly AuditLogger _audit;
    private readonly ILogger<EmployeesController> _logger;

    public EmployeesController(
        EmployeeRepository repository,
        EmployeeAccessPolicy accessPolicy,
        AuditLogger audit,
        ILogger<EmployeesController> logger)
    {
        _repository = repository;
        _accessPolicy = accessPolicy;
        _audit = audit;
        _logger = logger;
    }

    [HttpGet("{id:int}")]
    public ActionResult<Employee> GetById(int id)
    {
        var currentUser = UserContextFactory.From(User);
        var employee = _repository.GetById(id);

        if (employee is null)
        {
            return NotFound(new { message = $"Empleado {id} no existe." });
        }

        // El control que faltaba: autenticación no es autorización.
        if (!_accessPolicy.CanRead(currentUser, employee))
        {
            _audit.Log("access.denied", new { user = currentUser.UserId, targetId = id });
            return StatusCode(StatusCodes.Status403Forbidden,
                new { message = "No tiene permiso para consultar este registro." });
        }

        try
        {
            return Ok(employee);
        }
        catch (Exception ex)
        {
            // El detalle va al log, no al cliente.
            _logger.LogError(ex, "Error consultando empleado {EmployeeId}", id);
            return StatusCode(500, new { message = "Error interno. Contacte a soporte con el identificador de la traza." });
        }
    }
}
