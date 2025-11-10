
namespace ChatProjects.OrleansSilo
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.
            builder.AddServiceDefaults();

            builder.Services.AddControllers();
            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();
            builder.Host.UseOrleans(siloBuilder =>
            {
                // 在 Aspire 环境中，集群信息（哪些Silo是邻居）由 Aspire 自动处理
                // 我们只需要配置 Grain 的存储方式
                siloBuilder.UseLocalhostClustering(); // 本地开发时使用，Aspire 会自动覆盖

                // 配置 Grain 状态的持久化存储
                // 这里我们使用内存存储做演示，生产环境应换成 Redis, Azure Storage, or ADO.NET
                siloBuilder.AddMemoryGrainStorage("Default");
            });
            var app = builder.Build();
            app.MapDefaultEndpoints();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
            }

            app.UseHttpsRedirection();

            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
