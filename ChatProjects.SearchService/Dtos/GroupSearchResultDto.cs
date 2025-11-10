// SearchService/Dtos/SearchDtos.cs
namespace ChatProjects.SearchService.Dtos;

// 为了与 Flutter 客户端的 SearchResult 模型保持一致，我们调整了字段名
public record GroupSearchResultDto(
    int Id,
    string Title,       // 对应 Group.Name
    string Avatar,      // 对应 Group.AvatarUrl
    int Members,       // 对应 Group.MemberCount
    string OnlineStatus,
    List<string> Tags,
    string Description
);