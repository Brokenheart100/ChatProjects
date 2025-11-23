using IdGen;

namespace ChatProjects.ChatHistoryService.Utils;

public static class SnowflakeGenerator
{
    private static readonly IdGenerator _generator;

    static SnowflakeGenerator()
    {
        // 1. 获取机器 ID (GeneratorId/WorkerId)
        // 在分布式部署(K8s/Docker)中，每个实例必须有唯一的 ID (0-1023)。
        // 我们尝试从环境变量获取，如果没有配置则默认为 0。
        var workerIdEnv = Environment.GetEnvironmentVariable("WORKER_ID");
        int generatorId = 0;

        if (!string.IsNullOrEmpty(workerIdEnv) && int.TryParse(workerIdEnv, out int id))
        {
            generatorId = id;
        }

        // 2. 配置 Epoch (纪元/起始时间)
        // 这是一个基准时间，ID 是基于这个时间偏移生成的。
        // 建议设置为项目开始的大致时间（例如 2024-01-01），这样 ID 可以使用大约 69 年。
        var epoch = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        // 3. 配置 ID 结构 (使用默认结构即可：41位时间戳, 10位机器ID, 12位序列号)
        var structure = new IdStructure(41, 10, 12);

        // 4. 实例化 Generator
        var options = new IdGeneratorOptions(structure, new DefaultTimeSource(epoch));
        _generator = new IdGenerator(generatorId, options);
    }

    /// <summary>
    /// 生成下一个分布式唯一 ID (long)
    /// </summary>
    public static long NextId()
    {
        // IdGen 内部已经处理了线程安全(lock)和时钟回拨问题
        return _generator.CreateId();
    }
}