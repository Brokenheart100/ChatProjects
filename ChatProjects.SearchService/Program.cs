
using ChatProjects.SearchService.Data;

namespace ChatProjects.SearchService
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            builder.AddServiceDefaults();

            // 将 InMemoryDataStore 注册为单例，这样在整个应用生命周期中数据只会被创建一次
            builder.Services.AddSingleton<InMemoryDataStore>();
            builder.AddNpgsqlDbContext<UserDbContext>("userdb");
            builder.Services.AddControllers();
            builder.Services.AddOpenApi();

            var app = builder.Build();
            app.MapDefaultEndpoints();
            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
            }

            //app.UseHttpsRedirection();

            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
