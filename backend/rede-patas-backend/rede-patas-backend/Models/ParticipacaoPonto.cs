namespace rede_patas_backend.Models;

public class AcompanhamentoPonto
{
    public Guid UsuarioId { get; set; }
    public Guid PontoId { get; set; }
}

public class ManutencaoPonto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PontoId { get; set; }
    public Guid UsuarioId { get; set; }
    public Usuario Usuario { get; set; } = null!;
    public string Acao { get; set; } = "";
    public string Situacao { get; set; } = "";
    public DateTime CriadaEm { get; set; }
}
