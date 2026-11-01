using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using rede_patas_backend.Data;
using rede_patas_backend.Models;

namespace rede_patas_backend.Controllers;

[ApiController]
[Route("api/auth")]
[EnableRateLimiting("fixed")]
public class AuthController(ApiContext db, IPasswordHasher<Usuario> hasher,
    Microsoft.Extensions.Options.IOptionsMonitor<BearerTokenOptions> bearerOptions) : ControllerBase
{
    public record RegisterRequest(
        [Required, StringLength(150, MinimumLength = 2)] string Name,
        [Required, EmailAddress, StringLength(254)] string Email,
        [Required, StringLength(128, MinimumLength = 8)] string Password);
    public record LoginRequest([Required] string Email, [Required] string Password);
    public record RefreshRequest([Required] string RefreshToken);

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest request)
    {
        var name = request.Name.Trim();
        var email = request.Email.Trim().ToLowerInvariant();
        if (name.Length < 2 || !new EmailAddressAttribute().IsValid(email))
            return BadRequest(new { message = "Informe nome e e-mail válidos." });
        if (await db.Usuarios.AnyAsync(u => u.Email == email))
            return Conflict(new { message = "Este e-mail já está cadastrado." });
        
        var user = new Usuario 
            { 
                Nome = name, 
                Email = email 
            };
        user.SenhaHash = hasher.HashPassword(user, request.Password);
        db.Usuarios.Add(user);
        var session = CreateSession(user);
        try { 
            await db.SaveChangesAsync(); 
        }
        catch (DbUpdateException error) when (error.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            return Conflict(new { message = "Este e-mail já está cadastrado." });
        }
        return StatusCode(StatusCodes.Status201Created, session);
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await db.Usuarios.SingleOrDefaultAsync(u => u.Email == email);
        if (user is null || user.Status != "ativo") 
            return Unauthorized();
        var result = hasher.VerifyHashedPassword(user, user.SenhaHash, request.Password);
        if (result == PasswordVerificationResult.Failed) 
            return Unauthorized();
        if (result == PasswordVerificationResult.SuccessRehashNeeded)
            user.SenhaHash = hasher.HashPassword(user, request.Password);
        var session = CreateSession(user);
        await db.SaveChangesAsync();
        return Ok(session);
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var id = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var user = await db.Usuarios.FindAsync(id);
        return user is null || user.Status != "ativo" ? Unauthorized() : Ok(UserResponse(user));
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh(RefreshRequest request)
    {
        var hash = HashToken(request.RefreshToken);
        await using var transaction = await db.Database.BeginTransactionAsync();
        var token = await db.TokensRenovacao.Include(t => t.Usuario)
            .SingleOrDefaultAsync(t => t.TokenHash == hash);
        if (token is null || token.Usuario.Status != "ativo") return Unauthorized();
        var now = DateTime.UtcNow;
        // Consume only once, even when refresh requests arrive concurrently.
        var updated = await db.TokensRenovacao
            .Where(t => t.Id == token.Id && t.RevogadoEm == null && t.ExpiraEm > now)
            .ExecuteUpdateAsync(setters => setters.SetProperty(t => t.RevogadoEm, now));
        if (updated != 1) return Unauthorized();
        var session = CreateSession(token.Usuario);
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        return Ok(session);
    }

    [HttpPost("logout")]
    public async Task<IActionResult> Logout(RefreshRequest request)
    {
        var hash = HashToken(request.RefreshToken);
        await db.TokensRenovacao.Where(t => t.TokenHash == hash && t.RevogadoEm == null)
            .ExecuteUpdateAsync(setters => setters.SetProperty(t => t.RevogadoEm, DateTime.UtcNow));
        return NoContent();
    }

    private object CreateSession(Usuario user)
    {
        var expiresAt = DateTime.UtcNow.AddMinutes(15);
        var identity = new ClaimsIdentity(new[] {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Nome),
            new Claim(ClaimTypes.Email, user.Email)
        }, "Bearer");
        var ticket = new AuthenticationTicket(new ClaimsPrincipal(identity),
            new AuthenticationProperties { ExpiresUtc = expiresAt }, "Bearer");

        var accessToken = bearerOptions.Get("Bearer").BearerTokenProtector.Protect(ticket);
        var refreshToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        db.TokensRenovacao.Add(new TokenRenovacao {
            UsuarioId = user.Id, TokenHash = HashToken(refreshToken),
            ExpiraEm = DateTime.UtcNow.AddDays(30)
        });
        return new { user = UserResponse(user), accessToken, refreshToken, expiresAt };
    }

    private static object UserResponse(Usuario user) => new {
        id = user.Id.ToString(), name = user.Nome, email = user.Email
    };
    private static string HashToken(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
}
