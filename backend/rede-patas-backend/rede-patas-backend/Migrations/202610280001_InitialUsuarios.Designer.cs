using Microsoft.EntityFrameworkCore;

namespace rede_patas_backend.Migrations;

public partial class InitialUsuarios
{
    internal static void BuildInitialModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasAnnotation("ProductVersion", "10.0.14")
            .HasAnnotation("Relational:MaxIdentifierLength", 63);
        NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);
        modelBuilder.Entity("rede_patas_backend.Models.Usuario", b => {
            b.Property<Guid>("Id").ValueGeneratedOnAdd().HasColumnType("uuid").HasColumnName("id");
            b.Property<string>("Nome").IsRequired().HasMaxLength(150).HasColumnType("character varying(150)").HasColumnName("nome");
            b.Property<string>("Email").IsRequired().HasMaxLength(254).HasColumnType("character varying(254)").HasColumnName("email");
            b.Property<string>("SenhaHash").IsRequired().HasColumnType("text").HasColumnName("senha_hash");
            b.Property<string>("Status").IsRequired().HasMaxLength(20).HasColumnType("character varying(20)").HasColumnName("status");
            b.Property<DateTime>("CriadoEm").HasColumnType("timestamp with time zone").HasColumnName("criado_em");
            b.HasKey("Id");
            b.HasIndex("Email").IsUnique();
            b.ToTable("usuario");
        });
        modelBuilder.Entity("rede_patas_backend.Models.TokenRenovacao", b => {
            b.Property<Guid>("Id").ValueGeneratedOnAdd().HasColumnType("uuid").HasColumnName("id");
            b.Property<Guid>("UsuarioId").HasColumnType("uuid").HasColumnName("usuario_id");
            b.Property<string>("TokenHash").IsRequired().HasMaxLength(64).HasColumnType("character varying(64)").HasColumnName("token_hash");
            b.Property<DateTime>("ExpiraEm").HasColumnType("timestamp with time zone").HasColumnName("expira_em");
            b.Property<DateTime?>("RevogadoEm").HasColumnType("timestamp with time zone").HasColumnName("revogado_em");
            b.HasKey("Id");
            b.HasIndex("TokenHash").IsUnique();
            b.HasIndex("UsuarioId");
            b.ToTable("token_renovacao");
        });
        modelBuilder.Entity("rede_patas_backend.Models.TokenRenovacao", b => {
            b.HasOne("rede_patas_backend.Models.Usuario", "Usuario").WithMany()
                .HasForeignKey("UsuarioId").OnDelete(DeleteBehavior.Cascade).IsRequired();
            b.Navigation("Usuario");
        });
    }
}

