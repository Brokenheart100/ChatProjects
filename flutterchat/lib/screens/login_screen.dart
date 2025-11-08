import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutterchat/widgets/placeholder_avatar.dart';
import 'package:window_manager/window_manager.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;

  bool _isChecked = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

// 登录逻辑
  Future<void> _login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _apiService.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      // 登录成功，直接替换当前页面为 home 页面
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用 DragToMoveArea 包裹整个 Scaffold，使窗口任意位置可拖动
      body: DragToMoveArea(
        child: Container(
          decoration: const BoxDecoration(
            // 背景使用径向渐变来模拟截图效果
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                Color(0xFF3C3A5A), // 中心较亮的颜色
                Color(0xFF2C2B3D), // 边缘较暗的颜色
              ],
            ),
          ),
          child: Column(
            children: [
              _buildTitleBar(), // 自定义标题栏
              const SizedBox(height: 30),
              // QQ Logo
              const PlaceholderAvatar(
                text: 'QQ', // 2. 传入我们想显示的文字
                radius: 45, // 3. 设置头像半径
                fontSize: 32, // 4. 设置字体大小
              ),
              const SizedBox(height: 30),
              _buildInputField(_usernameController, '输入Username',
                  hasDropdown: true),
              const SizedBox(height: 15),
              _buildInputField(
                _passwordController,
                '输入Password',
              ),
              const SizedBox(height: 20),
              _buildAgreementCheckbox(),
              const SizedBox(height: 20),
              _buildLoginButton(),
              const Spacer(), // 填充剩余空间，将底部链接推到底部
              _buildBottomLinks(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 构建自定义标题栏
  Widget _buildTitleBar() {
    return Container(
      height: 40,
      color: Colors.transparent, // 透明背景以显示渐变
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Colors.white54, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white54, size: 20),
            onPressed: () => windowManager.minimize(),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }

  // 构建自定义输入框
  Widget _buildInputField(TextEditingController controller, String hintText,
      {bool isPassword = false, bool hasDropdown = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF8A8899), fontSize: 16),
          filled: true,
          fillColor: const Color(0xFF403E54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          suffixIcon: hasDropdown
              ? const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8A8899))
              : null,
        ),
      ),
    );
  }

  // 构建服务协议复选框和富文本
  Widget _buildAgreementCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 自定义复选框
          GestureDetector(
            onTap: () => setState(() => _isChecked = !_isChecked),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 1.5),
                color: _isChecked ? Colors.blue : Colors.transparent,
              ),
              child: _isChecked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          // 使用 RichText 实现链接效果
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontFamily: 'Microsoft YaHei'),
                children: [
                  const TextSpan(text: '已阅读并同意'),
                  TextSpan(
                    text: '服务协议',
                    style: const TextStyle(color: Color(0xFF5B8EDC)),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        print('服务协议 tapped');
                      },
                  ),
                  const TextSpan(text: '和'),
                  TextSpan(
                    text: 'QQ隐私保护指引',
                    style: const TextStyle(color: Color(0xFF5B8EDC)),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        print('隐私指引 tapped');
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建登录按钮
  Widget _buildLoginButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _login, // <-- 调用登录方法
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052D9),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                )
              : const Text('登录',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // 构建底部链接
  Widget _buildBottomLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {},
          child: const Text('扫码登录',
              style: TextStyle(color: Color(0xFF5B8EDC), fontSize: 14)),
        ),
        const Text('|', style: TextStyle(color: Colors.white24, fontSize: 14)),

        // --- 核心改动：将 TextButton 替换为 PopupMenuButton ---
        PopupMenuButton<String>(
          color: const Color(0xFF2E2E2E), // 菜单背景色
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onSelected: (value) {
            if (value == 'register') {
              // 跳转到注册页面
              Navigator.pushNamed(context, '/register');
            } else if (value == 'forgot_password') {
              print('忘记密码 tapped');
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            _buildPopupMenuItem(value: 'register', text: '注册账号'),
            _buildPopupMenuItem(value: 'forgot_password', text: '忘记密码'),
          ],
          // 按钮本身的样子
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('更多选项',
                style: TextStyle(color: Color(0xFF5B8EDC), fontSize: 14)),
          ),
        ),
      ],
    );
  }

  // --- 新增的辅助方法：构建弹出菜单的条目 ---
  PopupMenuItem<String> _buildPopupMenuItem(
      {required String value, required String text}) {
    return PopupMenuItem<String>(
      value: value,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
