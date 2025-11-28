using ChatProjects.Contracts.Events; // 引入群组事件契约（定义事件数据结构）
using MQTTnet; // MQTT核心库（消息队列遥测传输协议）
using MQTTnet.Extensions.ManagedClient; // MQTT托管客户端扩展（自动重连、消息队列等增强功能）
using System.Text.Json; // JSON序列化/反序列化工具

// 命名空间：实时服务的事件处理器模块
// 职责：接收领域事件，转换为前端可识别的信令，通过MQTT推送给目标用户
namespace ChatProjects.RealtimeService.Handlers;

/// <summary>
/// 群组事件处理器（专注处理群组创建事件）
/// 核心职责：将领域层的GroupCreatedEvent转换为MQTT系统信令，推送给群内所有成员
/// </summary>
/// <param name="mqttClient">MQTT托管客户端（依赖注入，负责发送MQTT消息）</param>
/// <param name="logger">日志组件（依赖注入，记录事件处理过程）</param>
public class GroupEventHandler(
    IManagedMqttClient mqttClient,
    ILogger<GroupEventHandler> logger)
{
    /// <summary>
    /// 处理群组创建事件的核心方法
    /// 触发时机：当领域层发布GroupCreatedEvent事件时，由事件总线调用
    /// </summary>
    /// <param name="event">群组创建事件数据（包含群组ID、名称、创建者、成员列表等核心信息）</param>
    /// <returns>异步任务（无返回值）</returns>
    public async Task Handle(GroupCreatedEvent @event)
    {
        // 记录事件接收日志（包含关键信息，便于问题排查和监控）
        logger.LogInformation(
            "📢 [GroupHandler] 收到建群事件: {GroupName}, 成员数: {MemberCount}, 群组ID: {GroupId}",
            @event.GroupName,
            @event.MemberIds.Count,
            @event.GroupId);

        // 1. 构造前端可识别的系统信令（Payload）
        // 设计思路：自定义JSON协议，通过type字段标识信令类型，前端根据type执行对应逻辑
        var signal = new
        {
            type = "SYSTEM_GROUP_CREATED", // 信令类型（固定值，前端需提前约定）：系统-群组创建
            data = new // 信令核心数据（仅包含前端所需字段，避免冗余）
            {
                groupId = @event.GroupId, // 群组唯一标识
                name = @event.GroupName, // 群组名称
                creatorId = @event.CreatorId, // 群组创建者ID
                createdAt = @event.CreatedAt // 群组创建时间
            }
        };

        // 将信令对象序列化为JSON字符串（MQTT消息体需为字节数组/字符串格式）
        var jsonPayload = JsonSerializer.Serialize(signal);

        // 2. 循环推送给群内所有成员（确保每个成员都能收到建群通知）
        foreach (var userId in @event.MemberIds)
        {
            // ⚠️ 关键设计：MQTT主题（Topic）格式定义
            // 格式：users/{用户ID}/system → 每个用户的专属系统消息频道
            // 优势：消息精准推送，仅目标用户能订阅，保证安全性和隔离性
            var topic = $"users/{userId}/system";

            // 构建MQTT应用消息
            var message = new MqttApplicationMessageBuilder()
                .WithTopic(topic) // 指定消息发送的主题（用户专属系统频道）
                .WithPayload(jsonPayload) // 设置消息体（JSON格式的系统信令）
                                          // QoS级别：AtLeastOnce（至少一次送达）
                                          // 特性：确保消息被接收，但可能重复（适合通知类消息，允许幂等处理）
                .WithQualityOfServiceLevel(MQTTnet.Protocol.MqttQualityOfServiceLevel.AtLeastOnce)
                .Build();

            // 将消息加入MQTT客户端的发送队列（托管客户端会自动处理发送、重连等逻辑）
            // 异步执行：不阻塞当前线程，提高并发处理能力
            await mqttClient.EnqueueAsync(message);

            // 调试日志（可选，生产环境可关闭）：记录单个用户的消息推送状态
            logger.LogDebug("🔄 [GroupHandler] 已将建群信令加入发送队列，目标用户: {UserId}, 主题: {Topic}", userId, topic);
        }

        // 记录事件处理完成日志（监控整个流程的执行结果）
        logger.LogInformation("✅ [GroupHandler] 建群信令已成功广播给所有成员，群组ID: {GroupId}, 推送成员数: {MemberCount}",
            @event.GroupId,
            @event.MemberIds.Count);
    }
}