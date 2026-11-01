using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using rede_patas_backend.Data;

namespace rede_patas_backend.Migrations;

[DbContext(typeof(ApiContext))]
[Migration("202610280001_InitialUsuarios")]
public partial class InitialUsuarios : Migration
{
    protected override void BuildTargetModel(ModelBuilder modelBuilder) =>
        BuildInitialModel(modelBuilder);

    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable("usuario", columns: table => new {
            id = table.Column<Guid>(type: "uuid", nullable: false),
            nome = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
            email = table.Column<string>(type: "character varying(254)", maxLength: 254, nullable: false),
            senha_hash = table.Column<string>(type: "text", nullable: false),
            status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
            criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
        }, constraints: table => table.PrimaryKey("PK_usuario", u => u.id));
        migrationBuilder.CreateTable("token_renovacao", columns: table => new {
            id = table.Column<Guid>(type: "uuid", nullable: false),
            usuario_id = table.Column<Guid>(type: "uuid", nullable: false),
            token_hash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
            expira_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
            revogado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
        }, constraints: table => {
            table.PrimaryKey("PK_token_renovacao", t => t.id);
            table.ForeignKey("FK_token_renovacao_usuario_usuario_id", t => t.usuario_id,
                "usuario", "id", onDelete: ReferentialAction.Cascade);
        });
        migrationBuilder.CreateIndex("IX_usuario_email", "usuario", "email", unique: true);
        migrationBuilder.CreateIndex("IX_token_renovacao_token_hash", "token_renovacao", "token_hash", unique: true);
        migrationBuilder.CreateIndex("IX_token_renovacao_usuario_id", "token_renovacao", "usuario_id");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable("token_renovacao");
        migrationBuilder.DropTable("usuario");
    }
}

