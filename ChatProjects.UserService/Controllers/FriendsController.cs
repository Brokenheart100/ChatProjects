using System.Security.Claims;
using ChatProjects.Contracts.Dtos;
using ChatProjects.UserService.Data;
using ChatProjects.UserService.Entities;
using ChatProjects.UserService.Services;
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
    private readonly RealtimeServiceApiClient _realtimeApiClient;
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
        var recipientExists = await _context.UserProfiles.AnyAsync(u => u.UserId== recipientId);
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

    // 文件: ChatProjects.UserService/Controllers/FriendsController.cs

    // (可以定义一些简单的自定义异常类，让代码更清晰)
    public class FriendRequestValidationException(string message) : Exception(message);
    public class NotAuthorizedException(string message) : Exception(message);


    [HttpPost("requests/{requestId:guid}/accept")]
    public async Task<IActionResult> AcceptRequest(Guid requestId)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId == null) return Unauthorized();

        var strategy = _context.Database.CreateExecutionStrategy();

        try
        {
            // --- 1. 在外部使用 try-catch 包裹 ExecuteAsync ---
            await strategy.ExecuteAsync(async () =>
            {
                await using var transaction = await _context.Database.BeginTransactionAsync();

                try
                {
                    var request = await _context.FriendRequests.FindAsync(requestId);

                    // --- 2. 在 lambda 内部，将 return 改为 throw ---
                    if (request == null)
                    {
                        // 抛出异常来终止操作
                        throw new FriendRequestValidationException("好友请求不存在。");
                    }
                    if (request.RecipientId != currentUserId)
                    {
                        throw new NotAuthorizedException("无权操作此好友请求。");
                    }
                    if (request.Status != FriendRequestStatus.Pending)
                    {
                        throw new FriendRequestValidationException("此请求已被处理。");
                    }
                    // ------------------------------------------

                    // (后续的数据库操作保持不变)
                    request.Status = FriendRequestStatus.Accepted;
                    request.UpdatedAt = DateTime.UtcNow;

                    var user1Id = string.Compare(request.SenderId, request.RecipientId) < 0 ? request.SenderId : request.RecipientId;
                    var user2Id = string.Compare(request.SenderId, request.RecipientId) < 0 ? request.RecipientId : request.SenderId;

                    if (!await _context.Friendships.AnyAsync(f => f.User1Id == user1Id && f.User2Id == user2Id))
                    {
                        var friendship = new Friendship { /* ... */ Id = Guid.NewGuid(), User1Id = user1Id, User2Id = user2Id, BecameFriendsAt = DateTime.UtcNow };
                        _context.Friendships.Add(friendship);
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    _logger.LogInformation("Friend request {RequestId} accepted.", requestId);
                }
                catch
                {
                    // 内部的 catch 只负责回滚和重新抛出
                    await transaction.RollbackAsync();
                    throw;
                }
            });
        }
        catch (FriendRequestValidationException ex)
        {
            // --- 3. 在外部捕获业务异常，并转换为对应的 HTTP 响应 ---
            // 根据异常消息，可以返回 NotFound 或 BadRequest
            if (ex.Message.Contains("不存在"))
            {
                return NotFound(new { Message = ex.Message });
            }
            return BadRequest(new { Message = ex.Message });
        }
        catch (NotAuthorizedException ex)
        {
            return Forbid(); // 直接返回 403 Forbidden
        }
        catch (Exception ex)
        {
            // 捕获所有其他异常（如数据库连接失败），返回 500
            _logger.LogError(ex, "An unhandled exception occurred while accepting friend request {RequestId}.", requestId);
            return StatusCode(500, new { Message = "处理请求时发生内部错误。" });
        }
        // -----------------------------------------------------------------

        // 如果没有任何异常，说明操作成功
        return Ok(new { Message = "好友添加成功" });
    }


    /// <summary>
    /// 获取当前登录用户的所有好友
    /// </summary>
    [HttpGet] // GET /api/friends
    public async Task<IActionResult> GetMyFriends()
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId == null) return Unauthorized();

        try
        {
            // 1. 在 Friendships 表中查找所有包含当前用户 ID 的记录
            var friendships = await _context.Friendships
                .Where(f => f.User1Id == currentUserId || f.User2Id == currentUserId)
                .ToListAsync();

            // 2. 从这些关系中，提取出所有好友的 ID
            var friendIds = friendships
                .Select(f => f.User1Id == currentUserId ? f.User2Id : f.User1Id)
                .ToList();

            if (!friendIds.Any())
            {
                // 如果没有任何好友，返回一个空列表
                return Ok(new List<UserSearchResultDto>());
            }

            // 3. 使用好友 ID 列表，去 UserProfiles 表中一次性查询出所有好友的详细信息
            var friends = await _context.UserProfiles
                .Where(up => friendIds.Contains(up.UserId))
                .Select(up => new UserSearchResultDto( // 复用我们已有的 DTO
                    up.UserId,
                    up.UserName,
                    up.AvatarUrl,
                    "IsFriend" // 明确地告诉前端这些人已经是好友
                ))
                .ToListAsync();

            _logger.LogInformation("User {UserId} fetched {FriendCount} friends.", currentUserId, friends.Count);

            return Ok(friends);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An error occurred while fetching friends for user {UserId}", currentUserId);
            return StatusCode(500, new { Message = "获取好友列表时发生内部错误。" });
        }
    }


    /// <summary>
    /// 获取当前登录用户收到的所有待处理的好友请求
    /// </summary>
    [HttpGet("requests/pending")] // GET /api/friends/requests/pending
    public async Task<IActionResult> GetPendingRequests()
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId == null) return Unauthorized();

        // 查找所有发给当前用户，且状态为 Pending 的请求
        var requests = await _context.FriendRequests
            .Where(r => r.RecipientId == currentUserId && r.Status == FriendRequestStatus.Pending)
            .ToListAsync();

        // 为了在 UI 上显示发送者的信息（名字、头像），我们需要 JOIN UserProfiles 表
        var senderIds = requests.Select(r => r.SenderId).ToList();

        var senders = await _context.UserProfiles
            .Where(up => senderIds.Contains(up.UserId))
            .ToDictionaryAsync(up => up.UserId); // 转换为字典以便快速查找

        // 组装成一个更丰富的 DTO 返回给前端
        var dtos = requests.Select(r => new FriendRequestDto(
            r.Id,
            r.SenderId,
            senders.GetValueOrDefault(r.SenderId)?.UserName ?? "未知用户",
            senders.GetValueOrDefault(r.SenderId)?.AvatarUrl,
            r.CreatedAt
        )).ToList();

        return Ok(dtos);
    }
    /// <summary>
    /// 拒绝一个好友请求
    /// </summary>
    [HttpPost("requests/{requestId:guid}/reject")]
    public async Task<IActionResult> RejectRequest(Guid requestId)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId == null) return Unauthorized();

        var request = await _context.FriendRequests.FindAsync(requestId);

        if (request == null)
            return NotFound(new { Message = "好友请求不存在。" });

        // 只能拒绝发给自己的请求
        if (request.RecipientId != currentUserId)
            return Forbid();

        if (request.Status != FriendRequestStatus.Pending)
            return BadRequest(new { Message = "此请求已被处理。" });

        request.Status = FriendRequestStatus.Rejected;
        request.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        _logger.LogInformation("User {UserId} rejected friend request {RequestId}", currentUserId, requestId);

        return Ok(new { Message = "已拒绝该好友请求" });
    }

    /// <summary>
    /// 获取当前用户收到的待处理好友请求的数量
    /// </summary>
    [HttpGet("requests/pending/count")] // GET /api/friends/requests/pending/count
    public async Task<IActionResult> GetPendingRequestsCount()
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId == null) return Unauthorized();

        // 直接在数据库中进行计数，效率最高
        var count = await _context.FriendRequests
            .CountAsync(r => r.RecipientId == currentUserId && r.Status == FriendRequestStatus.Pending);

        _logger.LogInformation("User {UserId} has {Count} pending friend requests.", currentUserId, count);

        // 返回一个简单的 JSON 对象，例如 { "count": 3 }
        return Ok(new { count });
    }
}