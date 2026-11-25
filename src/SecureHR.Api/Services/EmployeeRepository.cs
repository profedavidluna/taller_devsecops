using SecureHR.Api.Models;

namespace SecureHR.Api.Services;

/// <summary>
/// Repositorio de empleados. En producción habla con PostgreSQL; en el
/// laboratorio usamos datos en memoria para que el taller no dependa de
/// levantar una base de datos en los dos primeros minutos.
/// </summary>
public sealed class EmployeeRepository
{
    private readonly List<Employee> _employees = new()
    {
        new() { Id = 1,  FullName = "Ana Rodríguez Vargas",   Email = "ana.rodriguez@securehr.demo",   Department = "Engineering", Position = "Backend Developer",     Salary = 4800m, NationalId = "1-1111-0001" },
        new() { Id = 2,  FullName = "Carlos Jiménez Mora",    Email = "carlos.jimenez@securehr.demo",  Department = "Engineering", Position = "Tech Lead",              Salary = 6200m, NationalId = "1-1111-0002" },
        new() { Id = 3,  FullName = "María Fernández Rojas",  Email = "maria.fernandez@securehr.demo", Department = "Finance",     Position = "Financial Analyst",      Salary = 5100m, NationalId = "1-1111-0003" },
        new() { Id = 4,  FullName = "Luis Solano Chacón",     Email = "luis.solano@securehr.demo",     Department = "Finance",     Position = "Payroll Specialist",     Salary = 4300m, NationalId = "1-1111-0004" },
        new() { Id = 5,  FullName = "Sofía Ramírez Aguilar",  Email = "sofia.ramirez@securehr.demo",   Department = "People",      Position = "HR Business Partner",    Salary = 4700m, NationalId = "1-1111-0005" },
        new() { Id = 6,  FullName = "Diego Vargas Ulate",     Email = "diego.vargas@securehr.demo",    Department = "Engineering", Position = "QA Engineer",            Salary = 3900m, NationalId = "1-1111-0006" },
        new() { Id = 7,  FullName = "John Doe",               Email = "john.doe@securehr.demo",        Department = "Engineering", Position = "Junior Developer",       Salary = 2800m, NationalId = "1-1111-0007" },
        new() { Id = 8,  FullName = "Valeria Castro Núñez",   Email = "valeria.castro@securehr.demo",  Department = "Finance",     Position = "Controller",             Salary = 7100m, NationalId = "1-1111-0008" },
        new() { Id = 9,  FullName = "Andrés Mora Salas",      Email = "andres.mora@securehr.demo",     Department = "Engineering", Position = "DevOps Engineer",        Salary = 5900m, NationalId = "1-1111-0009" },
        new() { Id = 10, FullName = "Paula Rojas Méndez",     Email = "paula.rojas@securehr.demo",     Department = "People",      Position = "Recruiter",              Salary = 3600m, NationalId = "1-1111-0010" },
        new() { Id = 11, FullName = "Esteban Quesada Mora",   Email = "esteban.quesada@securehr.demo", Department = "Operations",  Position = "Facilities Coordinator", Salary = 3200m, NationalId = "1-1111-0011" },
        new() { Id = 12, FullName = "Natalia Solís Brenes",   Email = "natalia.solis@securehr.demo",   Department = "Operations",  Position = "Operations Manager",     Salary = 6800m, NationalId = "1-1111-0012" }
    };

    public IReadOnlyList<Employee> All() => _employees;

    public Employee? GetById(int id) => _employees.FirstOrDefault(e => e.Id == id);

    public IReadOnlyList<Employee> ByDepartment(string department) =>
        _employees.Where(e => string.Equals(e.Department, department, StringComparison.OrdinalIgnoreCase)).ToList();
}
