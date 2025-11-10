using Amazon.Auth.AccessControlPolicy;
using Amazon.S3.Model;
using Minio;
using Minio.DataModel.Args;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;


var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();


builder.Services.AddOpenTelemetry().WithTracing(tracerProviderBuilder =>
{
    tracerProviderBuilder
    .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(builder.Environment.ApplicationName))
    .AddSource("Wolverine");

});

//builder.Host.UseWolverine(opts =>
//{
//    opts.UseRabbitMqUsingNamedConnection("messaging").AutoProvision();
//    opts.PublishAllMessages().ToRabbitExchange("file-exchange");
//});

var minioBucketName = builder.Configuration["Minio:BucketName"] ?? "avatars";
builder.Services.AddMinio(configureClient => configureClient
    .WithEndpoint(builder.Configuration["Minio:Endpoint"])
    .WithCredentials(builder.Configuration["Minio:AccessKey"], builder.Configuration["Minio:SecretKey"])
    .WithSSL(false) // 如果你的 Minio 使用 HTTPS，请设置为 true
    .Build());

builder.Services.AddSingleton(minioBucketName);
builder.Services.AddControllers();
builder.Services.AddOpenApi();

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

