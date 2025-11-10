using Microsoft.AspNetCore.Mvc;
using Minio;
using Minio.DataModel.Args;

namespace ChatProjects.FileService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FilesController : ControllerBase
{
    // 将 IAmazonS3 替换为 IMinioClient
    private readonly IMinioClient _minioClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<FilesController> _logger;

    // 在构造函数中注入 IMinioClient
    public FilesController(IMinioClient minioClient, IConfiguration configuration, ILogger<FilesController> logger)
    {
        _minioClient = minioClient;
        _configuration = configuration;
        _logger = logger;
    }

    // GET /api/files/generate-upload-url
    [HttpGet("generate-upload-url")]
    public async Task<IActionResult> GenerateUploadUrl([FromQuery] string fileName)
    {
        if (string.IsNullOrWhiteSpace(fileName))
        {
            return BadRequest("文件名不能为空。");
        }

        // 从配置中读取存储桶名称，建议将 S3 改为 Minio 以便区分
        var bucketName = _configuration["Minio:BucketName"] ?? "avatars";
        var objectKey = $"{Guid.NewGuid()}-{fileName}"; // 生成唯一的文件名以防冲突

        try
        {
            var beArgs = new BucketExistsArgs().WithBucket(bucketName);
            var bucketExists = await _minioClient.BucketExistsAsync(beArgs);

            if (!bucketExists)
            {
                _logger.LogInformation("Bucket '{BucketName}' does not exist. Creating it...", bucketName);

                // 1. 创建存储桶
                var mbArgs = new MakeBucketArgs().WithBucket(bucketName);
                await _minioClient.MakeBucketAsync(mbArgs);
                _logger.LogInformation("Successfully created bucket '{BucketName}'.", bucketName);

                // --- 核心修复：创建桶之后，立刻为其设置公开读取策略 ---
                _logger.LogInformation("Setting public-read policy for bucket '{BucketName}'...", bucketName);

                // 2. 定义一个更简洁、更安全的只读策略
                var policyJson = $@"
                {{
                    ""Version"": ""2012-10-17"",
                    ""Statement"": [
                        {{
                            ""Effect"": ""Allow"",
                            ""Principal"": {{ ""AWS"": [""*""] }},
                            ""Action"": [""s3:GetObject""],
                            ""Resource"": [""arn:aws:s3:::{bucketName}/*""]
                        }}
                    ]
                }}";

                // 3. 设置策略
                var spArgs = new SetPolicyArgs()
                    .WithBucket(bucketName)
                    .WithPolicy(policyJson);
                await _minioClient.SetPolicyAsync(spArgs);
                _logger.LogInformation("Successfully set policy for bucket '{BucketName}'.", bucketName);
                // --------------------------------------------------------------------
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An error occurred while checking or creating bucket '{BucketName}'.", bucketName);
            return StatusCode(500, $"检查或创建存储桶失败: {ex.Message}");
        }

        // 使用 Minio SDK 创建用于 PUT 上传的预签名 URL 请求
        // 注意：这里使用 PresignedPutObjectAsync
        var expiryInSeconds = 60 * 5; // URL 5分钟后过期 (Minio SDK 以秒为单位)
        var presignedPutArgs = new PresignedPutObjectArgs()
            .WithBucket(bucketName)
            .WithObject(objectKey)
            .WithExpiry(expiryInSeconds);

        try
        {
            // 生成预签名 URL
            var url = await _minioClient.PresignedPutObjectAsync(presignedPutArgs).ConfigureAwait(false);

            // 返回 URL 和 objectKey，前端需要这两者来完成上传和后续的确认
            return Ok(new { uploadUrl = url, objectKey });
        }
        catch (Exception ex)
        {
            // 可以记录日志 ex
            return StatusCode(500, $"生成上传 URL 失败: {ex.Message}");
        }
    }
}
