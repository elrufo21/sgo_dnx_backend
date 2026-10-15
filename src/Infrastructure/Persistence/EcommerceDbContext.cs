using Ecommerce.Domain;
using Ecommerce.Domain.Common;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Ecommerce.Infrastructure.Persistence;

public class EcommerceDbContext : IdentityDbContext<Usuario>
{


    public EcommerceDbContext(DbContextOptions<EcommerceDbContext> options) : base(options)
    { }

    public override int SaveChanges()
    {
        PrepareChanges();
        return base.SaveChanges();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        PrepareChanges();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void PrepareChanges()
    {
        var userName = "system";

        foreach (var entry in ChangeTracker.Entries()
                     .Where(entry => entry.State is EntityState.Added or EntityState.Modified))
        {
            foreach (var property in entry.Properties)
            {
                if (property.Metadata.ClrType != typeof(string) ||
                    property.CurrentValue is not string value ||
                    IsIdentitySecret(property.Metadata.Name))
                {
                    continue;
                }

                property.CurrentValue = DbDepurarTexto(value);
            }
        }

        foreach (var entry in ChangeTracker.Entries<BaseDomainModel>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedDate = DateTime.Now;
                    entry.Entity.CreatedBy = userName;
                    break;

                case EntityState.Modified:
                    entry.Entity.LastModifiedDate = DateTime.Now;
                    entry.Entity.LastModifiedBy = userName;
                    break;
            }
        }

    }

    private static string DbDepurarTexto(string texto) =>
        texto.Replace("'", "")
            .Replace("[", "")
            .Replace("]", "")
            .Replace(";", "")
            .Replace("|", "")
            .Replace("¬", "")
            .Replace("}", "")
            .Replace("{", "");

    private static bool IsIdentitySecret(string propertyName) =>
        propertyName is nameof(IdentityUser.PasswordHash)
            or nameof(IdentityUser.SecurityStamp)
            or nameof(IdentityUser.ConcurrencyStamp);

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        
        builder.Entity<Usuario>().Property(x => x.Id).HasMaxLength(36); //250
        builder.Entity<Linea>().HasKey(a => a.IdSubLinea);
        builder.Entity<Usuario>().Property(x => x.NormalizedUserName).HasMaxLength(90);
        builder.Entity<IdentityRole>().Property(x => x.Id).HasMaxLength(36);
        builder.Entity<IdentityRole>().Property(x => x.NormalizedName).HasMaxLength(90);
    }

    public DbSet<Image>? Images { get; set; }
    public DbSet<Linea>? Linea { get; set; }
}
