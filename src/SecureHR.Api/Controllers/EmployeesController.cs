using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SecureHR.Api.Models;
using SecureHR.Api.Services;

namespace SecureHR.Api.Controllers;

[ApiController]
[Route("employees")]
[Authorize]
public sealed class EmployeesController : ControllerBase
{
    private readonly EmployeeRepository _repository;

    public EmployeesController(EmployeeRepository repository)
    {
        _repository = repository;
    }

    /// <summary>
    /// Devuelve la ficha de un empleado.
    /// El endpoint funciona. Tiene autenticación. Tiene pruebas.
    /// ¿Tiene autorización?
    /// </summary>
    [HttpGet("{id:int}")]
    public ActionResult<Employee> GetById(int id)
    {
        try
        {
            var employee = _repository.GetById(id);

            if (employee is null)
            {
                return NotFound(new { message = $"Empleado {id} no existe." });
            }

            // TODO(equipo): validar que el solicitante pueda ver este registro.
            return Ok(employee);
        }
        catch (Exception ex)
        {
            // Devolvemos el detalle para "facilitar el soporte".
            return StatusCode(500, ex.ToString());
        }
    }
}
