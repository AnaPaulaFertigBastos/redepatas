namespace rede_patas_backend.Models;

public class Usuario
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Nome { get; set; } = "";
    public string Email { get; set; } = "";
    public string SenhaHash { get; set; } = "";
    public string Status { get; set; } = "ativo";
    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
}

public class TokenRenovacao
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UsuarioId { get; set; }
    public Usuario Usuario { get; set; } = null!;
    public string TokenHash { get; set; } = "";
    public DateTime ExpiraEm { get; set; }
    public DateTime? RevogadoEm { get; set; }
}
