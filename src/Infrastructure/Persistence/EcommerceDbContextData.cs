using Ecommerce.Domain;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Ecommerce.Infrastructure.Persistence;


public class EcommerceDbContextData
{
    public static async Task LoadDataAsync(
        EcommerceDbContext context,
        UserManager<Usuario> usuarioManager,
        //RoleManager<IdentityRole> roleManager,
        ILoggerFactory loggerFactory
    )
    {
        try
        {
            if(!usuarioManager.Users.Any())
            {
                var usuarioAdmin = new Usuario
                {
                    Nombre = "Andre",
                    Apellido = "Ramirez Calla",
                    Email = "scotramirez1612@gmail.com",
                    UserName = "andre1612",
                    Telefono = "924228332",
                    AvatarUrl = "https://firebasestorage.googleapis.com/v0/b/edificacion-app.appspot.com/o/vaxidrez.jpg?alt=media&token=14a28860-d149-461e-9c25-9774d7ac1b24",
                };
                await usuarioManager.CreateAsync(usuarioAdmin, "PasswordJuanPerez123$");
                //await usuarioManager.AddToRoleAsync(usuarioAdmin, Role.ADMIN);

                var usuario = new Usuario
                {
                    Nombre = "Juan",
                    Apellido = "Perez",
                    Email = "juan.perez@gmail.com",
                    UserName = "juan.perez",
                    Telefono = "98563434534",
                    AvatarUrl = "https://firebasestorage.googleapis.com/v0/b/edificacion-app.appspot.com/o/avatar-1.webp?alt=media&token=58da3007-ff21-494d-a85c-25ffa758ff6d",
                };
                await usuarioManager.CreateAsync(usuario, "PasswordJuanPerez123$");
                //await usuarioManager.AddToRoleAsync(usuario, Role.USER);

            }

            if (await usuarioManager.FindByNameAsync("admin") is null)
            {
                await usuarioManager.CreateAsync(new Usuario
                {
                    Nombre = "Admin",
                    Apellido = "DXN",
                    Email = "admin@dxn.local",
                    UserName = "admin",
                    Telefono = "000000000"
                }, "DxnCusco123$");
            }

            if (await usuarioManager.FindByNameAsync("andre") is null)
            {
                var legacyUser = new Usuario
                {
                    Id = Guid.NewGuid().ToString(),
                    Nombre = "Andre",
                    Apellido = "DXN",
                    Email = "andre@dxn.local",
                    NormalizedEmail = "ANDRE@DXN.LOCAL",
                    UserName = "andre",
                    NormalizedUserName = "ANDRE",
                    Telefono = "5474121",
                    IsActive = true,
                    SecurityStamp = Guid.NewGuid().ToString(),
                    ConcurrencyStamp = Guid.NewGuid().ToString()
                };
                legacyUser.PasswordHash = new PasswordHasher<Usuario>()
                    .HashPassword(legacyUser, "5474121");
                context.Users.Add(legacyUser);
                await context.SaveChangesAsync();
            }
            
            if (!context.Images!.Any())
            {
                var imageSeedPath = "../Infrastructure/Data/image.json";
                if (File.Exists(imageSeedPath))
                {
                    var imageData = File.ReadAllText(imageSeedPath);
                    var imagenes = JsonConvert.DeserializeObject<List<Image>>(imageData);
                    await context.Images!.AddRangeAsync(imagenes!);
                    await context.SaveChangesAsync();
                }
            }
        
        }
        catch(Exception e)
        {
            var logger = loggerFactory.CreateLogger<EcommerceDbContextData>();
            logger.LogError(e.Message);
        }

    }
    
}
