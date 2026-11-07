using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using rede_patas_backend.Data;
using rede_patas_backend.Models;

namespace rede_patas_backend.Migrations;

[DbContext(typeof(ApiContext))]
[Migration("202611060001_ParticipacaoPontos")]
public class ParticipacaoPontos : Migration
{
    protected override void BuildTargetModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasAnnotation("ProductVersion", "10.0.14").HasAnnotation("Relational:MaxIdentifierLength", 63);
        NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);
        BuildParticipationModel(modelBuilder);
    }
    internal static void BuildParticipationModel(ModelBuilder modelBuilder)
    {
        PontosApoio.BuildPointModel(modelBuilder);
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
    }
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE TABLE acompanhamento_ponto (
            usuario_id uuid NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
            ponto_id uuid NOT NULL REFERENCES ponto_apoio(id) ON DELETE CASCADE,
            PRIMARY KEY (usuario_id, ponto_id)
        );
        CREATE INDEX "IX_acompanhamento_ponto_ponto_id" ON acompanhamento_ponto(ponto_id);
        CREATE TABLE manutencao_ponto (
            id uuid PRIMARY KEY,
            ponto_id uuid NOT NULL REFERENCES ponto_apoio(id) ON DELETE CASCADE,
            usuario_id uuid NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
            acao varchar(150) NOT NULL,
            situacao varchar(20) NOT NULL,
            criada_em timestamptz NOT NULL
        );
        CREATE INDEX "IX_manutencao_ponto_ponto_id" ON manutencao_ponto(ponto_id);
        CREATE INDEX "IX_manutencao_ponto_usuario_id" ON manutencao_ponto(usuario_id);
        CREATE INDEX "IX_manutencao_ponto_criada_em" ON manutencao_ponto(criada_em);
        """);
    protected override void Down(MigrationBuilder migrationBuilder) =>
        migrationBuilder.Sql("DROP TABLE manutencao_ponto; DROP TABLE acompanhamento_ponto;");
}
