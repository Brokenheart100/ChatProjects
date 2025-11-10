// 引入基础系统命名空间（提供控制台输出、异常处理等基础功能）
using System;
// 引入IO命名空间（提供文件操作相关类，如检查文件是否存在）
using System.IO;
// 引入异步任务命名空间（支持异步编程，MinIO操作多为异步方法）
using System.Threading.Tasks;
// 引入MinIO核心客户端命名空间（提供MinIO客户端及核心操作）
using Minio;
// 引入MinIO数据模型参数命名空间（包含各类操作所需的参数对象，如桶操作、上传操作的参数）
using Minio.DataModel.Args;

// 定义MinIO上传器类（包含程序入口和上传逻辑）
class MinioUploader
{
    // 异步主方法（程序入口），因为MinIO的操作多为异步，使用async/await简化异步逻辑
    static async Task Main(string[] args)
    {
        // 1. 配置MinIO服务器连接信息（需根据实际部署的MinIO环境修改）
        var endpoint = "localhost:9000"; // MinIO服务的地址和端口（默认端口9000，分布式部署可能不同）
        var accessKey = "minioadmin";    // 访问密钥（类似用户名，用于身份认证）
        var secretKey = "minioadmin";    // 密钥（类似密码，与accessKey配合进行认证）
        var useSsl = false;              // 是否启用SSL/TLS加密传输（本地测试通常为false，生产环境建议true）

        try
        {
            // 2. 初始化MinIO客户端实例
            // 采用链式调用配置客户端参数，最终通过Build()创建实例
            var minioClient = new MinioClient()
                                .WithEndpoint(endpoint)          // 设置MinIO服务的地址和端口
                                .WithCredentials(accessKey, secretKey)  // 设置认证凭据（accessKey和secretKey）
                                .WithSSL(useSsl)                 // 配置是否使用SSL加密传输
                                .Build();                        // 构建客户端实例

            Console.WriteLine("成功连接到 Minio 服务器。");  // 连接配置成功的提示（注意：此处仅表示客户端初始化成功，未实际建立连接）

            // 3. 定义目标存储桶名称（MinIO中用"桶"来组织文件，类似文件夹，但全局唯一）
            var bucketName = "images";

            // 4. 检查存储桶是否已存在
            // 创建桶存在性检查的参数对象，指定要检查的桶名
            var beArgs = new BucketExistsArgs().WithBucket(bucketName);
            // 调用MinIO客户端的异步方法检查桶是否存在，ConfigureAwait(false)用于避免不必要的线程上下文切换，提升性能
            bool found = await minioClient.BucketExistsAsync(beArgs).ConfigureAwait(false);

            if (!found)  // 如果桶不存在
            {
                Console.WriteLine($"存储桶 '{bucketName}' 不存在，正在创建...");
                // 创建创建桶的参数对象，指定要创建的桶名
                var mbArgs = new MakeBucketArgs().WithBucket(bucketName);
                // 调用异步方法创建桶
                await minioClient.MakeBucketAsync(mbArgs).ConfigureAwait(false);
                Console.WriteLine($"存储桶 '{bucketName}' 创建成功。");
            }
            else  // 如果桶已存在
            {
                Console.WriteLine($"存储桶 '{bucketName}' 已存在。");
            }

            // 5. 配置文件上传参数
            var objectName = "2023/june/uploaded-test.txt";  // 文件在MinIO存储桶中的名称（可与本地文件名不同，相当于存储后的"键"）
            var filePath = @"E:\Computer\CSharp\ChatProjects\MinioTest\test.txt";  // 本地待上传文件的完整路径（需确保文件真实存在）
            var contentType = "text/plain";        // 文件的MIME类型（用于标识文件格式，如text/plain为文本，image/jpeg为图片等）

            // 6. 检查本地文件是否存在（避免上传不存在的文件导致错误）
            if (!File.Exists(filePath))
            {
                Console.WriteLine($"错误：文件 '{filePath}' 不存在。");
                return;  // 文件不存在时退出程序
            }

            // 7. 执行文件上传操作
            Console.WriteLine($"正在上传文件: {filePath} 到存储桶: {bucketName}...");

            // 创建上传文件的参数对象，配置上传所需的关键信息
            var putObjectArgs = new PutObjectArgs()
                .WithBucket(bucketName)    // 指定目标存储桶
                .WithObject(objectName)    // 指定文件在存储桶中的名称（即对象名）
                .WithFileName(filePath)    // 指定本地待上传文件的路径
                .WithContentType(contentType);  // 指定文件的MIME类型

            // 调用MinIO客户端的异步上传方法，执行上传
            await minioClient.PutObjectAsync(putObjectArgs).ConfigureAwait(false);

            // 上传成功的提示
            Console.WriteLine($"文件 '{objectName}' 成功上传到存储桶 '{bucketName}'。");
        }
        catch (Exception ex)  // 捕获并处理所有可能的异常（如连接失败、权限不足、文件读写错误等）
        {
            Console.WriteLine($"上传失败: {ex.Message}");  // 输出错误信息（实际生产环境可记录详细日志）
        }
    }
}