using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL;
using rede_patas_backend.Data;
using rede_patas_backend.Models;

namespace rede_patas_backend.Migrations;

[DbContext(typeof(ApiContext))]
[Migration("202611030001_PontosApoio")]
public class PontosApoio : Migration
{
    protected override void BuildTargetModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasAnnotation("ProductVersion", "10.0.14")
            .HasAnnotation("Relational:MaxIdentifierLength", 63);
        NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);
        BuildPointModel(modelBuilder);
    }

    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("""
            CREATE TABLE ponto_apoio (
                id uuid PRIMARY KEY,
                criado_por_usuario_id uuid NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
                nome varchar(150) NOT NULL,
                descricao text NOT NULL,
                latitude numeric(9,6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
                longitude numeric(9,6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
                referencia_endereco varchar(250) NOT NULL,
                frequencia_abastecimento varchar(150) NOT NULL,
                responsavel_informado varchar(150) NOT NULL,
                quantidade_animais_estimada integer NOT NULL CHECK (quantidade_animais_estimada >= 0),
                situacao_geral varchar(20) NOT NULL,
                criado_em timestamptz NOT NULL,
                atualizado_em timestamptz NOT NULL
            );
            CREATE INDEX "IX_ponto_apoio_criado_por_usuario_id" ON ponto_apoio(criado_por_usuario_id);
            CREATE TABLE recurso (
                codigo varchar(20) PRIMARY KEY,
                nome varchar(50) NOT NULL
            );
            INSERT INTO recurso(codigo, nome) VALUES
                ('water', 'Água'), ('food', 'Ração'), ('shelter', 'Abrigo'), ('other', 'Outros');
            CREATE TABLE ponto_recurso (
                ponto_id uuid NOT NULL REFERENCES ponto_apoio(id) ON DELETE CASCADE,
                recurso_codigo varchar(20) NOT NULL REFERENCES recurso(codigo) ON DELETE RESTRICT,
                situacao varchar(20) NOT NULL CHECK (situacao IN ('disponivel', 'precisa_repor', 'indisponivel')),
                verificado_em timestamptz NULL,
                PRIMARY KEY (ponto_id, recurso_codigo)
            );
            CREATE INDEX "IX_ponto_recurso_recurso_codigo" ON ponto_recurso(recurso_codigo);
            CREATE TABLE foto (
                id uuid PRIMARY KEY,
                ponto_id uuid NOT NULL REFERENCES ponto_apoio(id) ON DELETE CASCADE,
                enviado_por_usuario_id uuid NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
                url_arquivo varchar(500) NOT NULL,
                criada_em timestamptz NOT NULL
            );
            CREATE INDEX "IX_foto_ponto_id" ON foto(ponto_id);
            CREATE INDEX "IX_foto_enviado_por_usuario_id" ON foto(enviado_por_usuario_id);
            """);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("DROP TABLE foto; DROP TABLE ponto_recurso; DROP TABLE recurso; DROP TABLE ponto_apoio;");
    }
    internal static void BuildPointModel(ModelBuilder modelBuilder)
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
}
