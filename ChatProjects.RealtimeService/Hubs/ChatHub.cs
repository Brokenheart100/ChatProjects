using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System;

namespace ChatProjects.RealtimeService.Hubs;
    [Authorize] // 关键！确保只有登录用户才能连接到 Hub
    public class ChatHub : Hub
    {

        private readonly ILogger<ChatHub> _logger;

        public ChatHub(ILogger<ChatHub> logger)
        {
            _logger = logger;
        }
        // 当一个客户端连接成功时，这个方法会被调用
        public override async Task OnConnectedAsync()
        {
            // 获取当前用户的 ID
            var userId = Context.UserIdentifier;

            // 将这个连接 ID 与用户 ID 关联起来，可以存入 Redis 或 Orleans Grain
            // 例如：await _presenceService.UserConnected(userId, Context.ConnectionId);

            // (可选) 将用户加入他所在的所有群组
            // var groups = await _groupService.GetMyGroups(userId);
            // foreach (var group in groups)
            // {
            //     await Groups.AddToGroupAsync(Context.ConnectionId, group.Id);
            // }

            _logger.LogInformation("User {UserId} connected with ConnectionId {ConnectionId}", userId, Context.ConnectionId);
            await base.OnConnectedAsync();
        }

        // 当客户端断开连接时
        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.UserIdentifier;
            // 清理用户与连接 ID 的关联
            // await _presenceService.UserDisconnected(userId, Context.ConnectionId);

            _logger.LogInformation("User {UserId} disconnected.", userId);
            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// 客户端调用的方法，用于发送私聊消息
        /// </summary>
        /// <param name="recipientId">接收者用户ID</param>
        /// <param name="message">消息内容</param>
        public async Task SendPrivateMessage(string recipientId, string message)
        {
            var senderId = Context.UserIdentifier;

            // TODO: 将消息持久化到 ChatHistoryService

            // 从在线状态服务（如 Redis 或 Orleans）获取接收者的所有连接 ID
            // var recipientConnectionIds = await _presenceService.GetConnectionsForUser(recipientId);

            // 为了演示，我们假设我们能直接找到接收者
            // "ReceiveMessage" 是我们将在客户端定义的方法名
            // 第一个参数是发送者信息，第二个是消息内容
            await Clients.User(recipientId).SendAsync("ReceiveMessage", new
            {
                SenderId = senderId,
                SenderName = Context.User?.Identity?.Name, // 从 Token 中获取用户名
                Text = message,
                Timestamp = DateTime.UtcNow
            });

            _logger.LogInformation("User {SenderId} sent message to {RecipientId}", senderId, recipientId);
        }
    }
