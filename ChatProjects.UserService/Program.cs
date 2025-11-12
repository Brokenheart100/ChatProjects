using System.Text;
using ChatProjects.UserService.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// --- 1. ע����� ---

builder.AddServiceDefaults();
builder.AddNpgsqlDbContext<UserDbContext>("userdb");


// **�����޸��������������ȷ�� JWT ��֤����**
var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = jwtSettings["SecretKey"];

// ����ϵͳĬ�ϵ���֤����ѯ������ "Bearer"
builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options => // ���� "Bearer" �����ľ�����֤����
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
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();


// --- 2. ����Ӧ�� ---
var app = builder.Build();

// --- 3. �����м���ܵ� ---

app.MapDefaultEndpoints();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseHttpsRedirection();

// **�����޸���������֤����Ȩ�м�� (˳�����Ҫ)**
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();


// --- 4. ����Ӧ�� ---
app.Run();