using Newtonsoft.Json;

namespace SecureHR.Api.Services;

/// <summary>
/// Bitácora de auditoría. Serializa eventos a JSON con Newtonsoft (decisión
/// heredada del equipo original: "ya estaba en el proyecto").
/// </summary>
public sealed class AuditLogger
{
    private static readonly JsonSerializerSettings Settings = new()
    {
        Formatting = Formatting.None,
        NullValueHandling = NullValueHandling.Ignore
    };

    public void Log(string action, object data)
    {
        var json = JsonConvert.SerializeObject(new { ts = DateTime.UtcNow, action, data }, Settings);
        Console.WriteLine($"[audit] {json}");
    }
}
