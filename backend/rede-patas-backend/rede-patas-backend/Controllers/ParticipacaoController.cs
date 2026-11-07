using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using rede_patas_backend.Data;
using rede_patas_backend.Models;

namespace rede_patas_backend.Controllers;

[ApiController, Authorize, EnableRateLimiting("fixed")]
[Route("api")]
public class ParticipacaoController(ApiContext db) : ControllerBase
{
    private async Task<Guid?> ActiveUser()
    {
        if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id)) return null;
        return await db.Usuarios.AnyAsync(u => u.Id == id && u.Status == "ativo") ? id : null;
    }

    [HttpGet("me/followed-points")]
    public async Task<IActionResult> Followed()
    {
        var user = await ActiveUser();
        if (user is null) return Unauthorized();
        return Ok(await db.Acompanhamentos.AsNoTracking().Where(a => a.UsuarioId == user)
            .Select(a => a.PontoId).ToListAsync());
    }

    [HttpPut("me/followed-points/{id:guid}")]
    public async Task<IActionResult> Follow(Guid id)
    {
        var user = await ActiveUser();
        if (user is null) return Unauthorized();
        if (!await db.PontosApoio.AnyAsync(p => p.Id == id)) return NotFound();
        // Idempotent even when two requests arrive simultaneously.
        await db.Database.ExecuteSqlInterpolatedAsync($"INSERT INTO acompanhamento_ponto (usuario_id, ponto_id) VALUES ({user.Value}, {id}) ON CONFLICT DO NOTHING");
        return NoContent();
    }

    [HttpDelete("me/followed-points/{id:guid}")]
    public async Task<IActionResult> Unfollow(Guid id)
    {
        var user = await ActiveUser();
        if (user is null) return Unauthorized();
        await db.Acompanhamentos.Where(a => a.UsuarioId == user && a.PontoId == id).ExecuteDeleteAsync();
        return NoContent();
    }

    [HttpGet("manutencoes")]
    public async Task<IActionResult> History()
    {
        if (await ActiveUser() is null) return Unauthorized();
        return Ok(await db.Manutencoes.AsNoTracking().OrderByDescending(m => m.CriadaEm).Take(500)
            .Select(m => new { id = m.Id, pointId = m.PontoId, action = m.Acao,
                author = m.Usuario.Nome, date = m.CriadaEm }).ToListAsync());
    }

    public record MaintenanceRequest(string? Status);

    [HttpPost("pontos/{id:guid}/maintenance")]
    public async Task<IActionResult> Maintain(Guid id, MaintenanceRequest request)
    {
        var user = await ActiveUser();
        if (user is null) return Unauthorized();
        var action = request.Status switch {
            "supplied" => "Abastecido / verificado", "attention" => "Precisa de manutenção",
            "needsWater" => "Falta água", "needsFood" => "Falta ração", _ => null
        };
        if (action is null) return BadRequest(new { message = "Situação de manutenção inválida." });
        // Serialize concurrent updates so the status and resource states agree.
        await using var transaction = await db.Database.BeginTransactionAsync();
        var point = await db.PontosApoio.FromSqlInterpolated($"SELECT * FROM ponto_apoio WHERE id = {id} FOR UPDATE").SingleOrDefaultAsync();
        if (point is null) return NotFound();
        await db.Entry(point).Collection(p => p.Recursos).LoadAsync();
        if ((request.Status == "needsWater" && !point.Recursos.Any(r => r.RecursoCodigo == "water")) ||
            (request.Status == "needsFood" && !point.Recursos.Any(r => r.RecursoCodigo == "food")))
            return BadRequest(new { message = "Este recurso não existe no ponto." });
        var now = DateTime.UtcNow;
        point.SituacaoGeral = request.Status!;
        point.AtualizadoEm = now;
        foreach (var resource in point.Recursos)
        {
            if (request.Status == "supplied") resource.Situacao = "disponivel";
            if ((request.Status == "needsWater" && resource.RecursoCodigo == "water") ||
                (request.Status == "needsFood" && resource.RecursoCodigo == "food"))
                resource.Situacao = "precisa_repor";
            resource.VerificadoEm = now;
        }
        var record = new ManutencaoPonto { PontoId = id, UsuarioId = user.Value,
            Acao = action, Situacao = request.Status!, CriadaEm = now };
        db.Manutencoes.Add(record);
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        var author = await db.Usuarios.Where(u => u.Id == user).Select(u => u.Nome).SingleAsync();
        return Ok(new { status = point.SituacaoGeral, updatedAt = now,
            maintenance = new { id = record.Id, pointId = id, action, author, date = now } });
    }
}
