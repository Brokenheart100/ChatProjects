namespace ChatProjects.UserService.Services;
// 定义一个临时的通知模型，最好把它放到 ChatProjects.Shared 中
public record PushNotification(string Type, object Data);

public class RealtimeServiceApiClient
{
    private readonly HttpClient _httpClient;

    public RealtimeServiceApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task PushToUserAsync(string userId, PushNotification notification)
    {
        try
        {
            // 调用 RealtimeService 中定义的内部 API
            var response = await _httpClient.PostAsJsonAsync($"/api/realtime/push/user/{userId}", notification);
            response.EnsureSuccessStatusCode();
        }
        catch (HttpRequestException ex)
        {
            // 在这里可以添加日志记录
            // _logger.LogError(ex, "Failed to push notification to user {UserId}", userId);
            // 暂时不向上抛出异常，因为推送失败不应该中断主流程
        }
    }
}
