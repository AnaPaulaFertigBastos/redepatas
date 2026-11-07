using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Npgsql.EntityFrameworkCore.PostgreSQL;
using rede_patas_backend.Data;
using rede_patas_backend.Models;

namespace rede_patas_backend.Migrations;

[DbContext(typeof(ApiContext))]
public class ApiContextModelSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasAnnotation("ProductVersion", "10.0.14")
            .HasAnnotation("Relational:MaxIdentifierLength", 63);
        NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);
        ParticipacaoPontos.BuildParticipationModel(modelBuilder);
    }

}
