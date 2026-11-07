using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using rede_patas_backend.Data;
using rede_patas_backend.Models;

namespace rede_patas_backend.Controllers;

[ApiController]
[Route("api/pontos")]
[EnableRateLimiting("fixed")]
public class PontosController(ApiContext db, IWebHostEnvironment environment) : ControllerBase
{
    private static readonly HashSet<string> AllowedResources = ["water", "food", "shelter", "other"];

    public record CreatePointRequest(string? Name, string? Description, decimal Latitude,
        decimal Longitude, string? Address, string? Schedule, string? Maintainer,
        int AnimalCount, List<string>? Resources, string? PhotoBase64);

    [HttpGet]
    public async Task<IActionResult> List()
    {
        var points = await db.PontosApoio.AsNoTracking().Include(p => p.Recursos)
            .Include(p => p.Fotos).OrderByDescending(p => p.CriadoEm).Take(500).ToListAsync();
        return Ok(points.Select(PointResponse));
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> Create(CreatePointRequest request)
    {
        var name = request.Name?.Trim() ?? "";
        var description = request.Description?.Trim() ?? "";
        var address = request.Address?.Trim() ?? "";
        var schedule = request.Schedule?.Trim() ?? "";
        var maintainer = request.Maintainer?.Trim() ?? "";
        var resources = request.Resources?.Distinct(StringComparer.Ordinal).ToList() ?? [];
        if (name.Length is < 2 or > 150 || description.Length is < 2 or > 2000 ||
            address.Length > 250 || schedule.Length > 150 || maintainer.Length > 150 ||
            request.Latitude is < -90 or > 90 || request.Longitude is < -180 or > 180 ||
            request.AnimalCount < 0 || resources.Count == 0 || resources.Any(r => !AllowedResources.Contains(r)))
            return BadRequest(new { message = "Confira os campos, as coordenadas e os recursos do ponto." });

        byte[]? image = null;
        string? extension = null;
        if (request.PhotoBase64 is not null)
        {
            if (request.PhotoBase64.Length > 7_000_000) return BadRequest(new { message = "Foto muito grande." });
            try { image = Convert.FromBase64String(request.PhotoBase64); }
            catch (FormatException) { return BadRequest(new { message = "Foto inválida." }); }
            if (image.Length > 5_000_000) return BadRequest(new { message = "Foto muito grande." });
            extension = image.AsSpan().StartsWith(new byte[] { 0xFF, 0xD8, 0xFF }) ? ".jpg" :
                image.AsSpan().StartsWith(new byte[] { 0x89, 0x50, 0x4E, 0x47 }) ? ".png" :
                image.Length >= 12 && image.AsSpan().StartsWith(new byte[] { 0x52, 0x49, 0x46, 0x46 }) && image.AsSpan(8).StartsWith(new byte[] { 0x57, 0x45, 0x42, 0x50 }) ? ".webp" : null;
            if (extension is null) return BadRequest(new { message = "Use uma foto JPEG, PNG ou WebP." });
        }

        if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ||
            !await db.Usuarios.AnyAsync(u => u.Id == userId && u.Status == "ativo"))
            return Unauthorized();
        var now = DateTime.UtcNow;
        var point = new PontoApoio {
            CriadoPorUsuarioId = userId, Nome = name, Descricao = description,
            Latitude = request.Latitude, Longitude = request.Longitude,
            ReferenciaEndereco = address, FrequenciaAbastecimento = schedule,
            ResponsavelInformado = maintainer, QuantidadeAnimaisEstimada = request.AnimalCount,
            CriadoEm = now, AtualizadoEm = now,
            Recursos = resources.Select(r => new PontoRecurso { RecursoCodigo = r, Situacao = "disponivel" }).ToList()
        };
        string? filePath = null;
        try
        {
            if (image is not null)
            {
                var uploadDir = Path.Combine(environment.ContentRootPath, "wwwroot", "uploads", "pontos");
                Directory.CreateDirectory(uploadDir);
                var fileName = $"{Guid.NewGuid():N}{extension}";
                filePath = Path.Combine(uploadDir, fileName);
                await System.IO.File.WriteAllBytesAsync(filePath, image);
                point.Fotos.Add(new FotoPonto { EnviadoPorUsuarioId = userId,
                    UrlArquivo = $"/uploads/pontos/{fileName}", CriadaEm = now });
            }
            db.PontosApoio.Add(point);
            await db.SaveChangesAsync();
        }
        catch
        {
            if (filePath is not null && System.IO.File.Exists(filePath)) System.IO.File.Delete(filePath);
            throw;
        }
        return Created($"/api/pontos/{point.Id}", PointResponse(point));
    }

    private static object PointResponse(PontoApoio point) => new {
        id = point.Id, name = point.Nome, description = point.Descricao,
        latitude = point.Latitude, longitude = point.Longitude,
        address = point.ReferenciaEndereco, schedule = point.FrequenciaAbastecimento,
        maintainer = point.ResponsavelInformado, animalCount = point.QuantidadeAnimaisEstimada,
        status = point.SituacaoGeral, updatedAt = point.AtualizadoEm,
        resources = point.Recursos.Select(r => r.RecursoCodigo).ToArray(),
        photoUrl = point.Fotos.FirstOrDefault()?.UrlArquivo
    };
}
