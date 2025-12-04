using StackExchange.Redis;

namespace ChatProjects.RealtimeService.Services;

public class UserStatusService(IConnectionMultiplexer redis)
{
    private readonly IDatabase _db = redis.GetDatabase();

    // 键名格式：user:status:{userId} -> Set<ClientId>
    private string GetKey(string userId) => $"user:status:{userId}";

    /// <summary>
    /// 设备上线
    /// </summary>
    /// <returns>如果这是该用户的第一个设备上线（即用户状态变为在线），返回 true</returns>
    public async Task<bool> DeviceConnectedAsync(string userId, string clientId)
    {
        var key = GetKey(userId);
        await _db.SetAddAsync(key, clientId);
        // 给 Key 设置过期时间（保底，防止僵尸数据），比如 24 小时
        await _db.KeyExpireAsync(key, TimeSpan.FromHours(24));

        // 如果集合数量是 1，说明之前是离线的，现在上线了
        var count = await _db.SetLengthAsync(key);
        return count == 1;
    }

    /// <summary>
    /// 设备下线
    /// </summary>
    /// <returns>如果这是该用户的最后一个设备下线（即用户状态变为离线），返回 true</returns>
    public async Task<bool> DeviceDisconnectedAsync(string userId, string clientId)
    {
        var key = GetKey(userId);
        await _db.SetRemoveAsync(key, clientId);

        var count = await _db.SetLengthAsync(key);
        return count == 0;
    }

    /// <summary>
    /// 批量检查在线状态
    /// </summary>
    public async Task<Dictionary<string, bool>> AreUsersOnlineAsync(List<string> userIds)
    {
        var result = new Dictionary<string, bool>();
        // 使用 Pipeline 批量查询提高性能
        var batch = _db.CreateBatch();
        var tasks = new List<Task<long>>();

        foreach (var id in userIds)
        {
            tasks.Add(batch.SetLengthAsync(GetKey(id)));
        }
        batch.Execute();
        await Task.WhenAll(tasks);

        for (int i = 0; i < userIds.Count; i++)
        {
            // 只要 Set 长度 > 0，即为在线
            result[userIds[i]] = tasks[i].Result > 0;
        }
        return result;
    }
}