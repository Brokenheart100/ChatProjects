
using Minio;

namespace TestAPI
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var endpoint = "play.min.io";
            var accessKey = "minioadmin";
            var secretKey = "minioadmin";
            {
                var builder = WebApplication.CreateBuilder(args);


                builder.Services.AddControllers();
                builder.Services.AddOpenApi();
                // Add Minio using the default endpoint
                builder.Services.AddMinio(accessKey, secretKey);

                // Add Minio using the custom endpoint and configure additional settings for default MinioClient initialization
                builder.Services.AddMinio(configureClient => configureClient
                    .WithEndpoint(endpoint)
                    .WithCredentials(accessKey, secretKey)
                .Build());

                var app = builder.Build();

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
}
