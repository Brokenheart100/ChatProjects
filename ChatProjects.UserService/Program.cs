// ChatProjects.UserService/Program.cs

using System.Text;
using ChatProjects.UserService.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// --- 1. 注册服务 ---

builder.AddServiceDefaults();
builder.AddNpgsqlDbContext<UserDbContext>("userdb");


//builder.Services.AddDbContext<UserDbContext>(options =>
//    options.UseNpgsql(builder.Configuration.GetConnectionString("userdb")));

// **核心修复：添加完整、正确的 JWT 认证配置**
var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = jwtSettings["SecretKey"];

// 告诉系统默认的认证和质询方案是 "Bearer"
builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options => // 配置 "Bearer" 方案的具体验证规则
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


// --- 2. 构建应用 ---
var app = builder.Build();

// --- 3. 配置中间件管道 ---

app.MapDefaultEndpoints();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseHttpsRedirection();

// **核心修复：启用认证和授权中间件 (顺序很重要)**
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();


// --- 4. 运行应用 ---
app.Run();