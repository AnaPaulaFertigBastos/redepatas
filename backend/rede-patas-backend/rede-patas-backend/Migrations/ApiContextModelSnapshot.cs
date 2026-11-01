using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using rede_patas_backend.Data;

namespace rede_patas_backend.Migrations;

[DbContext(typeof(ApiContext))]
public class ApiContextModelSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder) => InitialUsuarios.BuildInitialModel(modelBuilder);

}

