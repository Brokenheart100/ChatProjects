
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

namespace ChatProjects.GatewayService
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.

            builder.Services.AddControllers();
            builder.AddServiceDefaults();
            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            // 3. **���ģ�ע�� YARP ����������**
            //    ���������ļ� ("ReverseProxy" ��) ����·�ɺͼ�Ⱥ������
            builder.Services.AddReverseProxy()
                .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
                .AddServiceDiscoveryDestinationResolver();

            // 4. ���� CORS (������Դ����)
            //    �������� Flutter �ͻ��˻�������� Web Ӧ�÷��ʴ������������
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", policy =>
                {
                    policy.AllowAnyOrigin()      // �����κ���Դ (������������Ӧ����Ϊ����Ŀͻ��˵�ַ)
                        .AllowAnyMethod()     // �����κ� HTTP ���� (GET, POST, etc.)
                        .AllowAnyHeader();    // �����κ� HTTP ����ͷ
                });
            });

            var jwtSettings = builder.Configuration.GetSection("Jwt");
            var secretKey = jwtSettings["SecretKey"];

            builder.Services.AddAuthentication(options =>
                {
                    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
                })
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        ValidIssuer = jwtSettings["Issuer"],
                        ValidAudience = jwtSettings["Audience"],
                        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey!))
                    };
                });

            builder.Services.AddAuthorization();

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            //app.UseHttpsRedirection();
            app.UseCors("AllowAll");
            // ������֤����Ȩ�м�� (˳�����Ҫ)
            app.UseAuthentication();
            app.UseAuthorization();
            app.MapReverseProxy();

            app.MapControllers();

            app.Run();
        }
    }
}
