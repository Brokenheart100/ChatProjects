using System.Text.RegularExpressions;
using Group = ChatProjects.SearchService.Models.Group;

namespace ChatProjects.SearchService.Data;

// 使用单例模式来在内存中模拟一个数据库
public class InMemoryDataStore
{
    public List<Group> Groups { get; }
    public InMemoryDataStore()
    {
        Groups = new List<Group>
        {
            new Group
            {
                Id = 1,
                Name = "Flutter 开发者交流群",
                AvatarUrl = "assets/image/flutter_logo.png", // 暂时使用占位符
                MemberCount = 120,
                OnlineStatus = "100人在线",
                Tags = new List<string> { "flutter", "dart", "mobile" },
                Description = "一个专注于 Flutter 移动应用开发的交流社区。"
            },
            new Group
            {
                Id = 2,
                Name = ".NET Aspire 探索者",
                AvatarUrl = "assets/image/dotnet_logo.png",
                MemberCount = 88,
                OnlineStatus = "50人在线",
                Tags = new List<string> { "dotnet", "aspire", "microservices" },
                Description = "共同学习和探索 .NET Aspire 分布式应用开发。"
            },
            new Group
            {
                Id = 3,
                Name = "游戏开发同好会",
                AvatarUrl = "assets/image/game_logo.png",
                MemberCount = 250,
                OnlineStatus = "200人在线",
                Tags = new List<string> { "game", "unity", "unreal" },
                Description = "分享游戏开发经验，寻找一起做游戏的小伙伴！"
            }
        };
    }

    // 初始化一些模拟数据
}