namespace SecureHR.Api.Models;

/// <summary>
/// Resultado del reporte. En producción se ejecuta contra PostgreSQL;
/// en el laboratorio el motor está simulado y devolvemos la sentencia
/// generada para que el riesgo sea visible en pantalla.
/// </summary>
public sealed record ReportPreview(string Sql, int RowsReturned, string Engine);
