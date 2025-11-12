using System.Security.Claims;
using ChatProjects.Contracts.Dtos;
using ChatProjects.UserService.Data;
using ChatProjects.UserService.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// 好友关系控制器：处理好友请求的发送、接受等核心业务逻辑
/// 所有接口需授权访问（[Authorize]特性），路由前缀为/api/friends
/// </summary>
/// <remarks>
/// 构造函数：通过依赖注入获取数据库上下文和日志组件
/// </remarks>
/// <param name="context">用户服务数据库上下文</param>
/// <param name="logger">日志实例</param>
[ApiController]
[Route("api/[controller]")]
[Authorize] // 所有接口需登录后访问（依赖JWT认证）
public class FriendsController(UserDbContext context, ILogger<FriendsController> logger) : ControllerBase
{
    // 数据库上下文：用于操作用户、好友请求、好友关系等数据
    private readonly UserDbContext _context = context;
    // 日志组件：记录操作日志和异常信息
    private readonly ILogger<FriendsController> _logger = logger;

    /// <summary>
    /// 发送好友请求接口
    /// 接口路径：POST /api/friends/requests
    /// </summary>
    /// <param name="dto">包含接收者ID的请求参数</param>
    /// <returns>请求发送结果（成功/失败信息）</returns>
    [HttpPost("requests")]
    public async Task<IActionResult> SendRequest([FromBody] SendFriendRequestDto dto)
    {
        // 从JWT令牌中获取当前登录用户的唯一标识（ID）
        // ClaimTypes.NameIdentifier对应令牌中存储用户ID的声明
        var senderId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (senderId == null)
        {
            // 理论上不会触发（因[Authorize]确保已登录），但做防御性处理：未获取到用户ID则返回未授权
            return Unauthorized();
        }

        // 从请求参数中获取接收者ID
        var recipientId = dto.RecipientId;

        // --- 1. 基础验证：不能添加自己为好友 ---
        if (senderId == recipientId)
        {
            return BadRequest("不能添加自己为好友。");
        }

        // --- 2. 验证接收者是否存在 ---
        // 检查数据库中是否存在该接收者ID的用户
        var recipientExists = await _context.Users.AnyAsync(u => u.Id == recipientId);
        if (!recipientExists)
        {
            return NotFound("目标用户不存在。");
        }

        // --- 3. 验证是否已成为好友 ---
        // 为避免重复存储（如(A,B)和(B,A)视为同一关系），对两个用户ID按字符串排序
        // 确保User1Id始终是较小的ID，User2Id始终是较大的ID，保证数据一致性
        var user1Id = string.Compare(senderId, recipientId) < 0 ? senderId : recipientId;
        var user2Id = string.Compare(senderId, recipientId) < 0 ? recipientId : senderId;

        // 检查排序后的ID组合是否已存在于好友关系表中
        var areAlreadyFriends = await _context.Friendships
            .AnyAsync(f => f.User1Id == user1Id && f.User2Id == user2Id);
        if (areAlreadyFriends)
        {
            return Conflict("你们已经是好友了。");
        }

        // --- 4. 验证是否存在未处理的好友请求 ---
        // 检查双向请求：当前用户发给接收者，或接收者发给当前用户的请求
        var existingRequest = await _context.FriendRequests
            .FirstOrDefaultAsync(r =>
                (r.SenderId == senderId && r.RecipientId == recipientId) ||
                (r.SenderId == recipientId && r.RecipientId == senderId));

        if (existingRequest != null)
        {
            // 若存在待处理请求，不允许重复发送
            if (existingRequest.Status == FriendRequestStatus.Pending)
            {
                return Conflict("已发送过好友请求，请勿重复发送。");
            }
            // 注：此处简化处理，若之前请求被拒绝，也返回冲突；实际可根据业务需求允许重新发送
        }

        // --- 所有验证通过，创建新的好友请求 ---
        var newRequest = new FriendRequest
        {
            Id = Guid.NewGuid(), // 生成唯一标识
            SenderId = senderId, // 发送者ID（当前用户）
            RecipientId = recipientId, // 接收者ID
            Status = FriendRequestStatus.Pending, // 初始状态为"待处理"
            CreatedAt = DateTime.UtcNow // 记录UTC时间（避免时区问题）
        };

        try
        {
            // 将新请求添加到数据库上下文
            _context.FriendRequests.Add(newRequest);
            // 保存更改到数据库
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex)
        {
            // 捕获数据库更新异常（如网络问题、约束冲突等），记录错误日志
            _logger.LogError(ex, "发送好友请求时数据库更新失败。senderId:{SenderId}, recipientId:{RecipientId}", senderId, recipientId);
            return StatusCode(500, "服务器内部错误，请稍后重试。");
        }

        // TODO：通过消息队列（如RabbitMQ）或实时通信（如SignalR/Orleans）通知接收者有新请求
        // 示例：_messageBus.Publish(new FriendRequestReceivedEvent(senderId, recipientId));

        return Ok("好友请求已发送");
    }

    /// <summary>
    /// 接受好友请求接口
    /// 接口路径：POST /api/friends/requests/{requestId}/accept
    /// </summary>
    /// <param name="requestId">要接受的好友请求ID</param>
    /// <returns>处理结果（成功/失败信息）</returns>
    [HttpPost("requests/{requestId}/accept")]
    public async Task<IActionResult> AcceptRequest(Guid requestId)
    {
        // 获取当前登录用户ID（请求的接收者）
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId == null) return Unauthorized();

        // 开启数据库事务：确保"更新请求状态"和"创建好友关系"两个操作原子性（要么都成功，要么都失败）
        using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            // 1. 根据ID查询好友请求
            var request = await _context.FriendRequests.FindAsync(requestId);

            // 2. 验证请求合法性
            if (request == null)
            {
                return NotFound("好友请求不存在。");
            }
            if (request.RecipientId != currentUserId)
            {
                // 防止恶意操作：用户只能接受发给自己的请求
                return Forbid("无权操作此好友请求。");
            }
            if (request.Status != FriendRequestStatus.Pending)
            {
                // 避免重复处理：已接受/拒绝的请求不能再次处理
                return BadRequest("此请求已被处理。");
            }

            // 3. 更新请求状态为"已接受"
            request.Status = FriendRequestStatus.Accepted;
            _context.FriendRequests.Update(request);

            // 4. 创建好友关系记录
            // 再次对用户ID排序，保证与SendRequest中逻辑一致（User1Id < User2Id）
            var user1Id = string.Compare(request.SenderId, request.RecipientId) < 0 ? request.SenderId : request.RecipientId;
            var user2Id = string.Compare(request.SenderId, request.RecipientId) < 0 ? request.RecipientId : request.SenderId;

            var friendship = new Friendship
            {
                Id = Guid.NewGuid(), // 生成唯一标识
                User1Id = user1Id,
                User2Id = user2Id,
                BecameFriendsAt = DateTime.UtcNow // 记录成为好友的UTC时间
            };
            _context.Friendships.Add(friendship);

            // 5. 保存所有更改（更新请求+新增关系）
            await _context.SaveChangesAsync();

            // 6. 提交事务：所有操作成功后确认写入数据库
            await transaction.CommitAsync();

            // TODO：通过消息总线通知请求发送方"好友请求已被接受"

            return Ok("已添加好友。");
        }
        catch (Exception ex)
        {
            // 若发生任何异常，回滚事务：撤销所有未提交的更改
            await transaction.RollbackAsync();
            // 记录异常日志（包含请求ID和当前用户ID，便于排查）
            _logger.LogError(ex, "接受好友请求时发生错误。requestId:{RequestId}, currentUserId:{CurrentUserId}", requestId, currentUserId);
            return StatusCode(500, "处理请求时发生服务器内部错误。");
        }
    }
}