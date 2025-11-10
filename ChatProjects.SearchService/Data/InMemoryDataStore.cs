using System.Text.RegularExpressions;

namespace ChatProjects.SearchService.Data;

// 使用单例模式来在内存中模拟一个数据库
public class InMemoryDataStore
{
    public List<Group> Groups { get; } =
    [
      
    ];

    // 初始化一些模拟数据
}