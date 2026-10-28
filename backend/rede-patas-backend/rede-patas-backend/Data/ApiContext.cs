using Microsoft.EntityFrameworkCore;
namespace rede_patas_backend.Data
{
    public class ApiContext : DbContext
    {
        public ApiContext(DbContextOptions<ApiContext> options) : base(options)
        {
        }
    }
}
