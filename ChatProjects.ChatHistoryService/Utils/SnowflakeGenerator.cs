namespace ChatProjects.ChatHistoryService.Utils;

public static class SnowflakeGenerator
{
    // 这里使用 IdGen 库是最推荐的，但为了不让您报错，我们先用一个基于时间的简单实现
    // 在生产环境建议使用 NuGet: IdGen

    private static long _lastTimestamp = -1L;
    private static long _sequence = 0L;
    private static readonly object _lock = new object();

    public static long NextId()
    {
        lock (_lock)
        {
            var timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

            if (timestamp == _lastTimestamp)
            {
                _sequence = (_sequence + 1) & 4095;
                if (_sequence == 0)
                {
                    // 等待下一毫秒
                    while (timestamp <= _lastTimestamp)
                    {
                        timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
                    }
                }
            }
            else
            {
                _sequence = 0;
            }

            _lastTimestamp = timestamp;

            // 简单模拟雪花算法结构：时间戳 << 22 | 序列号
            // 注意：这里没有机器ID，分布式高并发下可能重复，但开发环境足够
            return (timestamp << 22) | _sequence;
        }
    }
}