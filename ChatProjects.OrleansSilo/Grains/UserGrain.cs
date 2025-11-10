using ChatProjects.Grains.Interfaces;

namespace ChatProjects.OrleansSilo.Grains;

// 定义 Grain 的状态，Orleans 会自动处理持久化
public class UserState
{
    public bool IsOnline { get; set; }
    public string? ConnectionId { get; set; }
}

// Grain 类需要继承 Grain<TState> 并实现接口
public class UserGrain : Grain<UserState>, IUserGrain
{
    public Task<bool> IsOnline()
    {
        return Task.FromResult(State.IsOnline);
    }

    public Task GoOnline(string connectionId)
    {
        State.IsOnline = true;
        State.ConnectionId = connectionId;
        // WriteStateAsync 告诉 Orleans 将内存中的状态持久化到存储中
        return WriteStateAsync();
    }

    public Task GoOffline()
    {
        State.IsOnline = false;
        State.ConnectionId = null;
        return WriteStateAsync();
    }

    public Task ReceiveMessage(string fromUser, string message)
    {
        // 在这里，你可以通过 SignalR 的 backplane
        // (比如直接注入一个 IHubContext)
        // 将消息推送到 this.State.ConnectionId
        Console.WriteLine($"User {this.GetPrimaryKeyString()} received message from {fromUser}: {message}");
        return Task.CompletedTask;
    }
}