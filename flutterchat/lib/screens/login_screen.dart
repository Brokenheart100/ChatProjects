import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

// Models & Services
import 'package:flutterchat/models/saved_account.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/repositories/auth_repository.dart';
import 'package:flutterchat/services/logger_service.dart';

// Widgets
import 'package:flutterchat/widgets/custom_circle_avatar.dart';

// ─── 局部 Provider ─────────────────────────────────────────────────────────────

/// 获取已保存的账号列表 (按最后登录时间倒序)
final savedAccountsProvider =
    FutureProvider.autoDispose<List<SavedAccount>>((ref) async {
  final service = ref.watch(accountServiceProvider);
  return await service.loadSavedAccounts();
});

// ─── 页面实现 ──────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with WindowListener {
  // UI 状态
  bool _isLoading = false;
  bool _isAgreementChecked = false;

  // 当前选中的历史账号 (用于高亮显示)
  SavedAccount? _selectedAccount;

  // 输入控制器
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── 业务逻辑 ────────────────────────────────────────────────────────────────

  /// 普通登录 (使用用户名 + 密码)
  Future<void> _handleLogin() async {
    if (_isLoading) return;

    // 1. 基础校验
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('请输入用户名和密码', isError: true);
      return;
    }
    if (!_isAgreementChecked) {
      _showSnackBar('请先同意服务协议', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);

      // 2. 调用仓库执行登录
      await repo.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      // 3. 跳转首页
      if (mounted) context.go('/chat');
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 快速登录 (点击头像)
  Future<void> _handleQuickLogin(SavedAccount account) async {
    // 选中状态更新
    setState(() {
      _selectedAccount = account;
      _usernameController.text = account.username;
      // 清空密码框，避免混淆
      if (_passwordController.text.isNotEmpty) _passwordController.clear();
    });

    // 如果未勾选协议，仅回填用户名，不发起请求
    if (!_isAgreementChecked) {
      _showSnackBar('请先同意服务协议', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);

      // 尝试使用 Token 恢复会话
      await repo.quickLogin(account);

      if (mounted) context.go('/chat');
    } catch (e) {
      logger.w("快速登录失效，转为手动输入: $e");
      if (mounted) {
        _showSnackBar("登录凭证已过期，请验证密码", isError: true);
        // 聚焦密码框
        FocusScope.of(context).requestFocus(FocusNode());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 删除账号
  Future<void> _removeAccount(String username) async {
    final service = ref.read(accountServiceProvider);
    await service.removeAccount(username);

    // 刷新列表
    ref.invalidate(savedAccountsProvider);

    // 如果删除的是当前选中的，重置状态
    if (_selectedAccount?.username == username) {
      setState(() {
        _selectedAccount = null;
        _usernameController.clear();
        _passwordController.clear();
      });
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── UI 构建 ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // 监听历史账号列表
    final accountsAsync = ref.watch(savedAccountsProvider);

    return Scaffold(
      body: DragToMoveArea(
        child: Container(
          // 背景渐变
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [Color(0xFF3C3A5A), Color(0xFF2C2B3D)],
            ),
          ),
          child: Column(
            children: [
              _buildTitleBar(),

              const Spacer(flex: 1), // 顶部留白

              // 1. 多账号头像列表
              SizedBox(
                height: 110,
                child: accountsAsync.when(
                  data: (accounts) => _buildAvatarList(accounts),
                  loading: () => const Center(child: SizedBox()),
                  error: (_, __) => const SizedBox(),
                ),
              ),

              const SizedBox(height: 20),

              // 2. 输入框区域 (带动画入场)
              _buildInputField(
                      controller: _usernameController,
                      hintText: '输入账号',
                      icon: Icons.person_outline)
                  .animate()
                  .fadeIn()
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 15),

              _buildInputField(
                      controller: _passwordController,
                      hintText: '输入密码',
                      icon: Icons.lock_outline,
                      isPassword: true)
                  .animate(delay: 100.ms)
                  .fadeIn()
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 20),

              // 3. 协议勾选
              _buildAgreementCheckbox(),

              const SizedBox(height: 25),

              // 4. 登录按钮
              _buildLoginButton()
                  .animate(delay: 200.ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.9, 0.9)),

              const Spacer(flex: 2), // 底部留白

              // 5. 底部链接
              _buildBottomLinks(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String? _hoveredUsername;

  /// 构建横向滚动的头像列表
  Widget _buildAvatarList(List<SavedAccount> accounts) {
    if (accounts.isEmpty) {
      // 如果没有历史账号，显示 App Logo
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text("FlutterChat",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      // 居中显示列表内容
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width > 400
              ? (MediaQuery.of(context).size.width - (accounts.length * 80)) / 2
              : 20),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        final isSelected = _selectedAccount?.username == account.username;

        // 判断当前是否悬停在这个 Item 上
        final isHovering = _hoveredUsername == account.username;

        return MouseRegion(
          // ✅ 1. 监听鼠标进出
          onEnter: (_) => setState(() => _hoveredUsername = account.username),
          onExit: (_) => setState(() => _hoveredUsername = null),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none, // 允许超出边界
                  children: [
                    // 头像主体
                    GestureDetector(
                      onTap: () => _handleQuickLogin(account),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF0052D9), width: 2)
                              : Border.all(color: Colors.transparent, width: 2),
                          // 选中时加一点发光，不选中不加
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color:
                                          const Color(0xFF0052D9).withAlpha(77),
                                      blurRadius: 10)
                                ]
                              : [],
                        ),
                        // 增加一个透明度动画，未选中且未悬停时稍微暗一点，聚焦更明显
                        child: Opacity(
                          opacity: (isSelected || isHovering) ? 1.0 : 0.8,
                          child: CustomCircleAvatar(
                            avatarUrl: account.avatarUrl,
                            radius: 28,
                          ),
                        ),
                      ),
                    ),

                    // ✅ 2. 删除按钮 (仅悬停时显示，带动画)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isHovering ? 1.0 : 0.0, // 悬停显示，否则隐藏
                        child: GestureDetector(
                          onTap: () => _removeAccount(account.username),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(77), // 改为半透明黑底，更优雅
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white24, width: 1),
                            ),
                            child: const Icon(Icons.close,
                                size: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 用户名
                Text(
                  account.username,
                  style: TextStyle(
                    color:
                        isSelected ? const Color(0xFF0052D9) : Colors.white70,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF403E54),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF8A8899), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF8A8899), size: 20),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            // 自动填充提示清除按钮
            suffixIcon: controller.text.isNotEmpty && !isPassword
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                    onPressed: () => setState(() => controller.clear()),
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}), // 触发刷新以显示/隐藏清除按钮
        ),
      ),
    );
  }

  Widget _buildAgreementCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () =>
                setState(() => _isAgreementChecked = !_isAgreementChecked),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _isAgreementChecked
                        ? const Color(0xFF0052D9)
                        : Colors.white54,
                    width: 1.5),
                color: _isAgreementChecked
                    ? const Color(0xFF0052D9)
                    : Colors.transparent,
              ),
              child: _isAgreementChecked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                children: [
                  const TextSpan(text: '已阅读并同意 '),
                  TextSpan(
                    text: '用户协议',
                    style:
                        const TextStyle(color: Color(0xFF5B8EDC)), // 1. 样式里只放颜色
                    mouseCursor: SystemMouseCursors.click, // 2. 光标放在这里
                    recognizer: TapGestureRecognizer()..onTap = () {},
                  ),
                  const TextSpan(text: ' 和 '),
                  TextSpan(
                    text: '隐私政策',
                    style:
                        const TextStyle(color: Color(0xFF5B8EDC)), // 1. 样式里只放颜色
                    mouseCursor: SystemMouseCursors.click, // 2. 光标放在这里
                    recognizer: TapGestureRecognizer()..onTap = () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052D9),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('登 录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildBottomLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
            onPressed: () {},
            child: const Text('找回密码',
                style: TextStyle(color: Colors.white38, fontSize: 13))),
        const SizedBox(width: 20),
        TextButton(
            onPressed: () => context.push('/register'), // 使用 GoRouter 跳转注册
            child: const Text('注册账号',
                style: TextStyle(color: Color(0xFF5B8EDC), fontSize: 13))),
      ],
    );
  }

  Widget _buildTitleBar() {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white38, size: 18),
            onPressed: () {},
            tooltip: "网络设置",
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
            onPressed: () => windowManager.minimize(),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            onPressed: () => windowManager.close(),
            hoverColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
