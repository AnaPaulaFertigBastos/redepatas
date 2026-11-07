namespace rede_patas_backend.Models;

public class PontoApoio
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CriadoPorUsuarioId { get; set; }
    public Usuario CriadoPorUsuario { get; set; } = null!;
    public string Nome { get; set; } = "";
    public string Descricao { get; set; } = "";
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public string ReferenciaEndereco { get; set; } = "";
    public string FrequenciaAbastecimento { get; set; } = "";
    public string ResponsavelInformado { get; set; } = "";
    public int QuantidadeAnimaisEstimada { get; set; }
    public string SituacaoGeral { get; set; } = "ativo";
    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
    public DateTime AtualizadoEm { get; set; } = DateTime.UtcNow;
    public List<PontoRecurso> Recursos { get; set; } = [];
    public List<FotoPonto> Fotos { get; set; } = [];
}

public class PontoRecurso
{
    public Guid PontoId { get; set; }
    public PontoApoio Ponto { get; set; } = null!;
    public string RecursoCodigo { get; set; } = "";
    public Recurso Recurso { get; set; } = null!;
    public string Situacao { get; set; } = "disponivel";
    public DateTime? VerificadoEm { get; set; }
}

public class Recurso
{
    public string Codigo { get; set; } = "";
    public string Nome { get; set; } = "";
}

public class FotoPonto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PontoId { get; set; }
    public PontoApoio Ponto { get; set; } = null!;
    public Guid EnviadoPorUsuarioId { get; set; }
    public string UrlArquivo { get; set; } = "";
    public DateTime CriadaEm { get; set; } = DateTime.UtcNow;
}
