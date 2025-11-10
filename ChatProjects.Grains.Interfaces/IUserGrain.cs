// 文件: ChatProjects.Grains.Interfaces/IUserGrain.cs
using Orleans;

namespace ChatProjects.Grains.Interfaces;

// IGrainWithGuidKey 表示这个 Grain 的 ID 是一个 Guid
public interface IUserGrain : IGrainWithStringKey
{
    // 记录用户上线，并保存其 SignalR ConnectionId
    Task GoOnline(string connectionId);

    // 记录用户下线
    Task GoOffline();

    // 检查用户是否在线
    Task<bool> IsOnline();

    // 接收私聊消息
    Task ReceiveMessage(string fromUser, string message);
}