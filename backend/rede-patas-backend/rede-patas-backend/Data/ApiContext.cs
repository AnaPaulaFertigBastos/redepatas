using Microsoft.EntityFrameworkCore;
namespace rede_patas_backend.Data
{
    using rede_patas_backend.Models;
    public class ApiContext : DbContext
    {
        public DbSet<AcompanhamentoPonto> Acompanhamentos => Set<AcompanhamentoPonto>();
        public DbSet<ManutencaoPonto> Manutencoes => Set<ManutencaoPonto>();
        public DbSet<Usuario> Usuarios => Set<Usuario>();
        public DbSet<TokenRenovacao> TokensRenovacao => Set<TokenRenovacao>();
        public DbSet<PontoApoio> PontosApoio => Set<PontoApoio>();
        public DbSet<PontoRecurso> PontosRecurso => Set<PontoRecurso>();
        public DbSet<Recurso> Recursos => Set<Recurso>();
        public DbSet<FotoPonto> FotosPonto => Set<FotoPonto>();

        protected override void OnModelCreating(ModelBuilder modelBuilder) => ConfigureModel(modelBuilder);

        public static void ConfigureModel(ModelBuilder modelBuilder)
        {
            var follow = modelBuilder.Entity<AcompanhamentoPonto>();
            follow.ToTable("acompanhamento_ponto");
            follow.HasKey(a => new { a.UsuarioId, a.PontoId });
            follow.HasIndex(a => a.PontoId);
            follow.Property(a => a.UsuarioId).HasColumnName("usuario_id");
            follow.Property(a => a.PontoId).HasColumnName("ponto_id");
            follow.HasOne<Usuario>().WithMany().HasForeignKey(a => a.UsuarioId).OnDelete(DeleteBehavior.Cascade);
            follow.HasOne<PontoApoio>().WithMany().HasForeignKey(a => a.PontoId).OnDelete(DeleteBehavior.Cascade);
            var maintenance = modelBuilder.Entity<ManutencaoPonto>();
            maintenance.ToTable("manutencao_ponto");
            maintenance.HasKey(m => m.Id);
            maintenance.Property(m => m.Id).HasColumnName("id");
            maintenance.Property(m => m.PontoId).HasColumnName("ponto_id");
            maintenance.Property(m => m.UsuarioId).HasColumnName("usuario_id");
            maintenance.Property(m => m.Acao).HasColumnName("acao").HasMaxLength(150).IsRequired();
            maintenance.Property(m => m.Situacao).HasColumnName("situacao").HasMaxLength(20).IsRequired();
            maintenance.Property(m => m.CriadaEm).HasColumnName("criada_em");
            maintenance.HasIndex(m => m.CriadaEm);
            maintenance.HasIndex(m => m.PontoId);
            maintenance.HasIndex(m => m.UsuarioId);
            maintenance.HasOne<PontoApoio>().WithMany().HasForeignKey(m => m.PontoId).OnDelete(DeleteBehavior.Cascade);
            maintenance.HasOne(m => m.Usuario).WithMany().HasForeignKey(m => m.UsuarioId).OnDelete(DeleteBehavior.Restrict);
            var usuario = modelBuilder.Entity<Usuario>();
            usuario.ToTable("usuario");
            usuario.HasKey(u => u.Id);
            usuario.Property(u => u.Id).HasColumnName("id");
            usuario.Property(u => u.Nome).HasColumnName("nome").HasMaxLength(150).IsRequired();
            usuario.Property(u => u.Email).HasColumnName("email").HasMaxLength(254).IsRequired();
            usuario.HasIndex(u => u.Email).IsUnique();
            usuario.Property(u => u.SenhaHash).HasColumnName("senha_hash").IsRequired();
            usuario.Property(u => u.Status).HasColumnName("status").HasMaxLength(20).IsRequired();
            usuario.Property(u => u.CriadoEm).HasColumnName("criado_em");
            var token = modelBuilder.Entity<TokenRenovacao>();
            token.ToTable("token_renovacao");
            token.HasKey(t => t.Id);
            token.Property(t => t.Id).HasColumnName("id");
            token.Property(t => t.UsuarioId).HasColumnName("usuario_id");
            token.Property(t => t.TokenHash).HasColumnName("token_hash").HasMaxLength(64).IsRequired();
            token.HasIndex(t => t.TokenHash).IsUnique();
            token.Property(t => t.ExpiraEm).HasColumnName("expira_em");
            token.Property(t => t.RevogadoEm).HasColumnName("revogado_em");
            token.HasIndex(t => t.UsuarioId);
            token.HasOne(t => t.Usuario).WithMany().HasForeignKey(t => t.UsuarioId).OnDelete(DeleteBehavior.Cascade);
            var ponto = modelBuilder.Entity<PontoApoio>();
            ponto.ToTable("ponto_apoio", t => {
                t.HasCheckConstraint("CK_ponto_latitude", "latitude BETWEEN -90 AND 90");
                t.HasCheckConstraint("CK_ponto_longitude", "longitude BETWEEN -180 AND 180");
                t.HasCheckConstraint("CK_ponto_quantidade", "quantidade_animais_estimada >= 0");
            });
            ponto.HasKey(p => p.Id);
            ponto.Property(p => p.Id).HasColumnName("id");
            ponto.Property(p => p.CriadoPorUsuarioId).HasColumnName("criado_por_usuario_id");
            ponto.HasIndex(p => p.CriadoPorUsuarioId);
            ponto.HasOne(p => p.CriadoPorUsuario).WithMany().HasForeignKey(p => p.CriadoPorUsuarioId).OnDelete(DeleteBehavior.Restrict);
            ponto.Property(p => p.Nome).HasColumnName("nome").HasMaxLength(150).IsRequired();
            ponto.Property(p => p.Descricao).HasColumnName("descricao").IsRequired();
            ponto.Property(p => p.Latitude).HasColumnName("latitude").HasColumnType("numeric(9,6)");
            ponto.Property(p => p.Longitude).HasColumnName("longitude").HasColumnType("numeric(9,6)");
            ponto.Property(p => p.ReferenciaEndereco).HasColumnName("referencia_endereco").HasMaxLength(250).IsRequired();
            ponto.Property(p => p.FrequenciaAbastecimento).HasColumnName("frequencia_abastecimento").HasMaxLength(150).IsRequired();
            ponto.Property(p => p.ResponsavelInformado).HasColumnName("responsavel_informado").HasMaxLength(150).IsRequired();
            ponto.Property(p => p.QuantidadeAnimaisEstimada).HasColumnName("quantidade_animais_estimada");
            ponto.Property(p => p.SituacaoGeral).HasColumnName("situacao_geral").HasMaxLength(20).IsRequired();
            ponto.Property(p => p.CriadoEm).HasColumnName("criado_em");
            ponto.Property(p => p.AtualizadoEm).HasColumnName("atualizado_em");
            var recurso = modelBuilder.Entity<PontoRecurso>();
            recurso.ToTable("ponto_recurso", t => t.HasCheckConstraint("CK_ponto_recurso_situacao", "situacao IN ('disponivel', 'precisa_repor', 'indisponivel')"));
            recurso.HasKey(r => new { r.PontoId, r.RecursoCodigo });
            recurso.Property(r => r.PontoId).HasColumnName("ponto_id");
            recurso.Property(r => r.RecursoCodigo).HasColumnName("recurso_codigo").HasMaxLength(20);
            recurso.Property(r => r.Situacao).HasColumnName("situacao").HasMaxLength(20).IsRequired();
            recurso.Property(r => r.VerificadoEm).HasColumnName("verificado_em");
            recurso.HasIndex(r => r.RecursoCodigo);
            recurso.HasOne(r => r.Ponto).WithMany(p => p.Recursos).HasForeignKey(r => r.PontoId).OnDelete(DeleteBehavior.Cascade);
            recurso.HasOne(r => r.Recurso).WithMany().HasForeignKey(r => r.RecursoCodigo).OnDelete(DeleteBehavior.Restrict);
            var catalogo = modelBuilder.Entity<Recurso>();
            catalogo.ToTable("recurso");
            catalogo.HasKey(r => r.Codigo);
            catalogo.Property(r => r.Codigo).HasColumnName("codigo").HasMaxLength(20);
            catalogo.Property(r => r.Nome).HasColumnName("nome").HasMaxLength(50).IsRequired();
            var foto = modelBuilder.Entity<FotoPonto>();
            foto.ToTable("foto");
            foto.HasKey(f => f.Id);
            foto.Property(f => f.Id).HasColumnName("id");
            foto.Property(f => f.PontoId).HasColumnName("ponto_id");
            foto.Property(f => f.EnviadoPorUsuarioId).HasColumnName("enviado_por_usuario_id");
            foto.Property(f => f.UrlArquivo).HasColumnName("url_arquivo").HasMaxLength(500).IsRequired();
            foto.Property(f => f.CriadaEm).HasColumnName("criada_em");
            foto.HasIndex(f => f.PontoId);
            foto.HasIndex(f => f.EnviadoPorUsuarioId);
            foto.HasOne(f => f.Ponto).WithMany(p => p.Fotos).HasForeignKey(f => f.PontoId).OnDelete(DeleteBehavior.Cascade);
            foto.HasOne<Usuario>().WithMany().HasForeignKey(f => f.EnviadoPorUsuarioId).OnDelete(DeleteBehavior.Restrict);
        }
        public ApiContext(DbContextOptions<ApiContext> options) : base(options)
        {
        }
    }
}
