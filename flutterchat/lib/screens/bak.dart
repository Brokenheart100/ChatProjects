import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'; // 确保导入 LeanFlutter fork，支持 DragToMoveArea
import '../models/search_result.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with WindowListener {
  // 修复：添加 with WindowListener
  // 模拟的搜索结果数据（统一路径为 assets/images/）
  final List<SearchResult> _results = [
    // 重命名：原始数据
    SearchResult(
        avatar: 'assets/images/search1.jpg', // 修复：统一路径
        title: '王者姑妈茶话会',
        members: 413,
        onlineStatus: '30+人在聊天',
        tags: ['男生多', '游戏', '王者荣耀', '王者荣耀-王者'],
        description: '孩子, 打王者/瓦/原/铲/洲/瓦/劫/吃鸡吗?'),
    SearchResult(
        avatar: 'assets/images/search2.jpg',
        title: '重生之我在杖剑-傲立寒江公会当黑奴',
        members: 34,
        onlineStatus: '10+人在聊天',
        tags: ['男生多', '游戏', '仗剑传说'],
        description: ''),
    SearchResult(
        avatar: 'assets/images/search3.jpg',
        title: '电气PLC自动化电工1群',
        members: 1010,
        onlineStatus: '10+人在聊天',
        tags: ['男生多', '咨询', '西门子PLC'],
        description: '本群旨在汇聚各路自动化人才, 以西门子工控自动化产品硬件、软件技术交流为主, 三菱、'),
    SearchResult(
        avatar: 'assets/images/search4.jpg',
        title: 'lolm手游开黑群',
        members: 348,
        onlineStatus: '10+人在聊天',
        tags: ['男生多', '游戏', '原神'],
        description: 'LOLM手游交流开黑群, 妹妹多, 大佬多'),
    SearchResult(
        avatar: 'assets/images/search5.jpg',
        title: '乐趣MU S21.1·十字军·S',
        members: 146,
        onlineStatus: '5+人在聊天',
        tags: ['男生多'],
        description: ''),
    SearchResult(
        avatar: 'assets/images/search6.jpg',
        title: '浓米派主题',
        members: 1929,
        onlineStatus: '5+人在聊天',
        tags: ['男生多', '其他', 'MIUI主题'],
        description: '●申请入会请说明理由。●天气时钟失可双指捏合后台后添加2*4时钟恢复。●锁屏壁纸和时钟'),
    SearchResult(
        avatar: 'assets/images/search7.jpg',
        title: '王者模拟战精英群',
        members: 493,
        onlineStatus: '10+人在聊天',
        tags: ['男生多', '游戏', '模拟战', '王者荣耀-王者段位'],
        description: '开局6045次'),
  ];

  final TextEditingController _searchController =
      TextEditingController(); // 修复：定义控制器
  List<SearchResult> _filteredResults = []; // 过滤后结果
  int _selectedTabIndex = 0;
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredResults = List.from(_results); // 修复：使用 _results 初始化
    _searchController.addListener(_filterResults); // 修复：绑定监听
    windowManager.addListener(this); // 添加窗口监听
  }

  @override
  void dispose() {
    _searchController.dispose();
    windowManager.removeListener(this); // 移除监听
    super.dispose();
  }

  // 过滤逻辑（支持搜索 + 简单标签过滤）
  void _filterResults() {
    String query = _searchController.text.toLowerCase();
    // 简单标签过滤示例（根据 _selectedFilterIndex）
    final selectedFilter = _getFilterByIndex();
    setState(() {
      _filteredResults = _results.where((result) {
        bool matchesQuery = result.title.toLowerCase().contains(query) ||
            result.description.toLowerCase().contains(query) ||
            result.tags.any((tag) => tag.toLowerCase().contains(query));
        bool matchesFilter = selectedFilter.isEmpty ||
            result.tags.any((tag) =>
                tag.toLowerCase().contains(selectedFilter.toLowerCase()));
        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  // 辅助：获取当前筛选标签
  String _getFilterByIndex() {
    final filters = ['推荐', '游戏', '动漫', '学习', '音乐', '影视', '运动'];
    return filters[_selectedFilterIndex];
  }

  // WindowListener 覆盖
  @override
  void onWindowFocus() {
    if (mounted) setState(() {}); // 刷新 UI
  }

  @override
  void onWindowClose() async {
    // 指南推荐：使用 setPreventClose 处理确认
    await windowManager.setPreventClose(false); // 允许关闭
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2D2A),
        title: const Text('确认关闭？', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消', style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('关闭', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (shouldClose != true) {
      await windowManager.setPreventClose(true); // 阻止关闭
    } else {
      await windowManager.close(); // 标准关闭
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      // 修复：用 Material 包裹，避免嵌套 MaterialApp 冲突
      color: const Color(0xFF2E2D2A),
      child: Scaffold(
        backgroundColor: const Color(0xFF2E2D2A),
        body: Column(
          children: [
            _buildTitleBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // 构建可拖动的自定义标题栏（修复：导入 DragToMoveArea）
  Widget _buildTitleBar() {
    return DragToMoveArea(
      child: Container(
        height: 40,
        color: const Color(0xFF2E2D2A),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Text('综合搜索',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const Spacer(),
            IconButton(
                onPressed: () => windowManager.minimize(),
                icon:
                    const Icon(Icons.remove, size: 16, color: Colors.white70)),
            IconButton(
                onPressed: () async {
                  final isMax = await windowManager.isMaximized();
                  if (isMax) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
                icon: const Icon(Icons.crop_square,
                    size: 16, color: Colors.white70)),
            IconButton(
                onPressed: () => windowManager.close(),
                icon: const Icon(Icons.close, size: 16, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  // 构建主内容区域
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildTabs(),
          const SizedBox(height: 12),
          _buildFilterChips(),
          const SizedBox(height: 20),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  // 构建搜索栏
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '输入关键词',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _filterResults,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC9C960),
            foregroundColor: Colors.black,
            minimumSize: const Size(100, 40),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('搜索',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  // 构建顶部标签页（添加简单过滤逻辑示例）
  Widget _buildTabs() {
    final tabs = ['全部', '用户', '群聊', '小程序', '机器人'];
    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = _selectedTabIndex == index;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedTabIndex = index);
            // 示例：切换标签时重置搜索并过滤（根据 tabs 扩展 _filterResults）
            _searchController.clear();
            _filterResults(); // 触发过滤
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Column(
              children: [
                Text(
                  tabs[index],
                  style: TextStyle(
                    color:
                        isSelected ? const Color(0xFFC9C960) : Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 3,
                    color: const Color(0xFFC9C960),
                  )
              ],
            ),
          ),
        );
      }),
    );
  }

  // 构建筛选标签（添加过滤逻辑）
  Widget _buildFilterChips() {
    final filters = ['推荐', '游戏', '动漫', '学习', '音乐', '影视', '运动'];
    return SingleChildScrollView(
      // 新增：允许水平滚动
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilterIndex = index);
              _filterResults(); // 触发过滤
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3A546D)
                    : const Color(0xFF3C3B38),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color:
                      isSelected ? Colors.lightBlue.shade200 : Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 构建搜索结果列表（修复：统一使用 _filteredResults，并添加空提示）
  Widget _buildResultsList() {
    if (_filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text('无匹配结果',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text('尝试调整关键词或筛选条件',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _filteredResults.length, // 修复：使用 _filteredResults
      itemBuilder: (context, index) {
        final item = _filteredResults[index]; // 修复：统一
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                  radius: 24, backgroundImage: AssetImage(item.avatar)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 14, color: Colors.white54),
                        Text(' ${item.members}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                        const SizedBox(width: 16),
                        ...item.tags.map((tag) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3C3B38),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(tag,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            )),
                      ],
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  // 示例：加入群聊逻辑（可扩展为新窗口或回调）
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('加入 "${item.title}"')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white30),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('加入'),
              ),
            ],
          ),
        );
      },
    );
  }
}
