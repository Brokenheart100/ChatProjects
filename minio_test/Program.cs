// 引入Minio客户端核心命名空间，用于操作Minio对象存储服务
using Minio;
// 引入Minio数据模型参数命名空间，包含各类操作所需的参数类
using Minio.DataModel.Args;

namespace minio_test
{

    // 程序入口静态类
    public static class Program
    {
        // Minio服务端点（服务地址），此处使用Minio官方测试服务地址
        var endpoint = "play.min.io";
        // 访问密钥（类似用户名），测试环境默认密钥
        var accessKey = "minioadmin";
        // 密钥（类似密码），测试环境默认密钥
        var secretKey = "minioadmin";

        // 程序主入口方法
        public static void Main(string[] args)
        {
            // 创建Web应用构建器，用于配置服务和应用管道
            var builder = WebApplication.CreateBuilder();

            // 方式1：使用默认端点注册Minio客户端服务
            // 注：默认端点通常为本地或配置文件中预设的地址，此处传入访问密钥和密钥进行认证
            builder.Services.AddMinio(accessKey, secretKey);

            // 方式2：使用自定义端点注册Minio客户端服务，并配置额外初始化参数
            // 通过配置委托自定义客户端：指定服务端点、认证凭据，最后构建客户端
            builder.Services.AddMinio(configureClient => configureClient
                .WithEndpoint(endpoint)  // 设置Minio服务地址
                .WithCredentials(accessKey, secretKey)  // 设置认证信息
                .Build());  // 构建客户端实例

            // 注意：SSL配置（启用HTTPS）和Build()方法已由内置服务自动处理，无需重复调用

            // 构建应用实例
            var app = builder.Build();
            // 运行应用（启动Web服务器）
            app.Run();
        }
    }

    // 标记为API控制器（自动启用API相关特性，如模型验证、路由推断等）
    [ApiController]
    // 示例控制器：直接注入Minio客户端实例使用
    public class ExampleController : ControllerBase
    {
        // Minio客户端接口实例（通过依赖注入获取）
        private readonly IMinioClient minioClient;

        // 构造函数：通过依赖注入初始化Minio客户端
        public ExampleController(IMinioClient minioClient)
        {
            this.minioClient = minioClient;
        }

        // 定义HTTP GET请求处理方法
        [HttpGet]
        // 声明成功响应类型：返回字符串，HTTP状态码200
        [ProducesResponseType(typeof(string), StatusCodes.Status200OK)]
        // 生成指定存储桶（bucket）的预签名GET URL（用于临时访问对象）
        public async Task<IActionResult> GetUrl(string bucketID)
        {
            // 调用Minio客户端的预签名GET对象方法，传入存储桶参数
            // 预签名URL允许在不暴露密钥的情况下临时访问对象
            var presignedUrl = await minioClient.PresignedGetObjectAsync(
                new PresignedGetObjectArgs()
                    .WithBucket(bucketID)  // 指定目标存储桶ID
            ).ConfigureAwait(false);

            // 返回生成的预签名URL（HTTP 200）
            return Ok(presignedUrl);
        }
    }

    // 标记为API控制器
    [ApiController]
    // 示例控制器：通过Minio客户端工厂创建客户端实例使用
    public class ExampleFactoryController : ControllerBase
    {
        // Minio客户端工厂接口（用于动态创建客户端实例）
        private readonly IMinioClientFactory minioClientFactory;

        // 构造函数：通过依赖注入初始化Minio客户端工厂
        public ExampleFactoryController(IMinioClientFactory minioClientFactory)
        {
            this.minioClientFactory = minioClientFactory;
        }

        // 定义HTTP GET请求处理方法
        [HttpGet]
        // 声明成功响应类型：返回字符串，HTTP状态码200
        [ProducesResponseType(typeof(string), StatusCodes.Status200OK)]
        // 生成指定存储桶的预签名GET URL（通过工厂创建客户端）
        public async Task<IActionResult> GetUrl(string bucketID)
        {
            // 通过工厂创建Minio客户端实例
            // 注：CreateClient方法可接受可选参数，用于动态配置客户端（如临时修改端点、密钥等）
            var minioClient = minioClientFactory.CreateClient();

            // 生成并返回预签名URL
            var presignedUrl = await minioClient.PresignedGetObjectAsync(
                new PresignedGetObjectArgs()
                    .WithBucket(bucketID)
            ).ConfigureAwait(false);

            return Ok(presignedUrl);
        }
    }
}