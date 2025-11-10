// 引入必要的命名空间
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http; // 提供StatusCodes
using Microsoft.AspNetCore.Mvc;
using Minio;
using Minio.DataModel.Args; // 提供PresignedGetObjectArgs

namespace TestAPI.Controllers;

// 标记为API控制器，并配置路由（必填，否则无法访问）
[ApiController]
[Route("api/[controller]")] // 路由格式：api/ExampleFactory
public class ExampleFactoryController : ControllerBase
{
    // 注入MinIO客户端工厂
    private readonly IMinioClientFactory _minioClientFactory;

    // 构造函数：通过依赖注入初始化工厂
    public ExampleFactoryController(IMinioClientFactory minioClientFactory)
    {
        _minioClientFactory = minioClientFactory;
    }

    // HTTP GET请求处理方法，路由：api/ExampleFactory/geturl
    [HttpGet("geturl")]
    // 声明成功响应类型：字符串（预签名URL），状态码200
    [ProducesResponseType(typeof(string), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetUrl(string bucketID, string objectName, int expirySeconds = 3600)
    {
        // 校验参数（避免空值导致错误）
        if (string.IsNullOrEmpty(bucketID))
            return BadRequest("bucketID不能为空");
        if (string.IsNullOrEmpty(objectName))
            return BadRequest("objectName不能为空");

        // 通过工厂创建MinIO客户端实例
        var minioClient = _minioClientFactory.CreateClient();

        // 构建预签名URL参数（补充必填的对象名称和过期时间）
        var args = new PresignedGetObjectArgs()
            .WithBucket(bucketID)       // 存储桶名称
            .WithObject(objectName)     // 要访问的对象（文件）名称
            .WithExpiry(expirySeconds); // URL过期时间（秒，默认1小时）

        // 生成预签名URL
        var presignedUrl = await minioClient.PresignedGetObjectAsync(args)
            .ConfigureAwait(false);

        // 返回预签名URL
        return Ok(presignedUrl);
    }
}