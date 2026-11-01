using Microsoft.EntityFrameworkCore;
namespace rede_patas_backend.Data
{
    using rede_patas_backend.Models;
    public class ApiContext : DbContext
    {
        public DbSet<Usuario> Usuarios => Set<Usuario>();
        public DbSet<TokenRenovacao> TokensRenovacao => Set<TokenRenovacao>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
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
            token.HasOne(t => t.Usuario).WithMany().HasForeignKey(t => t.UsuarioId);
        }
        public ApiContext(DbContextOptions<ApiContext> options) : base(options)
        {
        }
    }
}
