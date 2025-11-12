import 'package:flutter/gestures.dart'; // 手势识别库，用于处理复杂手势（如富文本链接点击）
import 'package:flutter/material.dart'; // Flutter核心UI组件库
import 'package:flutterchat/widgets/placeholder_avatar.dart'; // 自定义占位头像组件
import 'package:window_manager/window_manager.dart'; // 窗口管理库（用于桌面应用窗口控制，如最小化、关闭）
import '../services/api_service.dart'; // 导入API服务，用于调用登录接口

/// 登录屏幕组件
/// 负责展示登录界面、处理用户输入、调用登录接口及跳转逻辑
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiService = ApiService(); // API服务实例，用于调用登录接口
  bool _isLoading = false; // 登录按钮加载状态（true表示正在请求中，禁用重复点击）
  bool _isChecked = false; // 服务协议复选框状态（true表示已同意）
  final _usernameController = TextEditingController(); // 用户名输入控制器（获取用户输入的用户名）
  final _passwordController = TextEditingController(); // 密码输入控制器（获取用户输入的密码）

  /// 登录逻辑处理
  /// 1. 检查是否正在加载，防止重复提交
  /// 2. 调用API服务的登录方法
  /// 3. 登录成功则跳转到首页，失败则显示错误提示
  Future<void> _login() async {
    if (_isLoading) return; // 如果正在加载，直接返回（防止重复点击）
    setState(() => _isLoading = true); // 开始加载，更新UI状态

    try {
      // 调用API服务的登录方法，传入用户名和密码
      final authResponse = await _apiService.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      // 登录成功：替换当前页面为首页，并传递用户信息（authResponse）
      Navigator.pushReplacementNamed(context, '/home', arguments: authResponse);
    } catch (e) {
      // 登录失败：显示错误提示（e为错误信息）
      _showSnackBar(e.toString(), isError: true);
    } finally {
      // 无论成功/失败，最终都重置加载状态（需判断页面是否已挂载，避免 setState 报错）
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 显示底部提示条（SnackBar）
  /// [message]：提示内容
  /// [isError]：是否为错误提示（true为红色，false为绿色）
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green, // 根据类型设置背景色
    ));
  }

  /// 页面销毁时释放资源
  /// 释放文本控制器，避免内存泄漏
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 构建登录页面UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用DragToMoveArea包裹整个界面（桌面应用特性），使窗口可通过任意区域拖动
      body: DragToMoveArea(
        child: Container(
          // 背景使用径向渐变，从中心亮色调到边缘暗色调
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter, // 渐变中心在顶部
              radius: 1.5, // 渐变半径
              colors: [
                Color(0xFF3C3A5A), // 中心颜色
                Color(0xFF2C2B3D), // 边缘颜色
              ],
            ),
          ),
          // 垂直布局：标题栏、Logo、输入框、复选框、登录按钮、底部链接
          child: Column(
            children: [
              _buildTitleBar(), // 自定义标题栏（包含设置、最小化、关闭按钮）
              const SizedBox(height: 30),
              // 显示"QQ"文字的占位头像（模拟QQ登录界面Logo）
              const PlaceholderAvatar(
                text: 'QQ', // 头像显示的文字
                radius: 45, // 头像半径
                fontSize: 32, // 文字大小
              ),
              const SizedBox(height: 30),
              // 用户名输入框（带下拉箭头）
              _buildInputField(_usernameController, '输入Username',
                  hasDropdown: true),
              const SizedBox(height: 15),
              // 密码输入框（默认不显示下拉箭头，可通过isPassword参数控制是否加密显示）
              _buildInputField(
                _passwordController,
                '输入Password',
                isPassword: true, // 这里补充原代码缺失的密码加密显示参数
              ),
              const SizedBox(height: 20),
              _buildAgreementCheckbox(), // 服务协议复选框和富文本链接
              const SizedBox(height: 20),
              _buildLoginButton(), // 登录按钮
              const Spacer(), // 填充剩余空间，将底部链接推至底部
              _buildBottomLinks(), // 底部链接（扫码登录、更多选项）
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建自定义标题栏
  /// 包含设置按钮、最小化按钮、关闭按钮（桌面应用窗口控制）
  Widget _buildTitleBar() {
    return Container(
      height: 40, // 标题栏高度
      color: Colors.transparent, // 透明背景，显示下方的渐变背景
      child: Row(
        children: [
          const Spacer(), // 左侧空白填充，将按钮推至右侧
          // 设置按钮（暂未实现功能）
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Colors.white54, size: 20),
            onPressed: () {},
          ),
          // 最小化按钮（调用windowManager.minimize()最小化窗口）
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white54, size: 20),
            onPressed: () => windowManager.minimize(),
          ),
          // 关闭按钮（调用windowManager.close()关闭窗口）
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }

  /// 构建自定义输入框
  /// [controller]：文本控制器（关联输入框内容）
  /// [hintText]：提示文字
  /// [isPassword]：是否为密码框（true则加密显示）
  /// [hasDropdown]：是否显示下拉箭头（用户名框显示，密码框不显示）
  Widget _buildInputField(TextEditingController controller, String hintText,
      {bool isPassword = false, bool hasDropdown = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40), // 左右边距40
      child: TextFormField(
        controller: controller, // 绑定控制器
        obscureText: isPassword, // 是否加密显示（密码框为true）
        style: const TextStyle(color: Colors.white, fontSize: 16), // 输入文字样式
        decoration: InputDecoration(
          hintText: hintText, // 提示文字
          hintStyle:
              const TextStyle(color: Color(0xFF8A8899), fontSize: 16), // 提示文字样式
          filled: true, // 启用填充色
          fillColor: const Color(0xFF403E54), // 输入框背景色
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // 圆角8
            borderSide: BorderSide.none, // 无边框
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // 内边距
          suffixIcon: hasDropdown
              ? const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF8A8899)) // 下拉箭头（用户名框）
              : null,
        ),
      ),
    );
  }

  /// 构建服务协议复选框和富文本
  /// 包含自定义复选框和可点击的"服务协议"、"隐私保护指引"链接
  Widget _buildAgreementCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40), // 左右边距40
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // 水平居中
        children: [
          // 自定义复选框（圆形，选中时显示蓝色背景和对勾）
          GestureDetector(
            onTap: () => setState(() => _isChecked = !_isChecked), // 点击切换选中状态
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle, // 圆形
                border: Border.all(color: Colors.white54, width: 1.5), // 边框
                color: _isChecked ? Colors.blue : Colors.transparent, // 选中时蓝色背景
              ),
              child: _isChecked
                  ? const Icon(Icons.check,
                      size: 12, color: Colors.white) // 选中时显示对勾
                  : null,
            ),
          ),
          const SizedBox(width: 8), // 复选框与文字间距
          // 富文本：包含普通文本和可点击链接
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontFamily: 'Microsoft YaHei'), // 基础文字样式
                children: [
                  const TextSpan(text: '已阅读并同意'),
                  // "服务协议"链接
                  TextSpan(
                    text: '服务协议',
                    style: const TextStyle(color: Color(0xFF5B8EDC)), // 链接文字颜色
                    recognizer: TapGestureRecognizer() // 手势识别器（处理点击）
                      ..onTap = () {
                        print('服务协议 tapped'); // 点击事件（可跳转协议页面）
                      },
                  ),
                  const TextSpan(text: '和'),
                  // "QQ隐私保护指引"链接
                  TextSpan(
                    text: 'QQ隐私保护指引',
                    style: const TextStyle(color: Color(0xFF5B8EDC)), // 链接文字颜色
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        print('隐私指引 tapped'); // 点击事件
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

  /// 构建登录按钮
  /// 加载状态显示圆形进度条，正常状态显示"登录"文字
  Widget _buildLoginButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40), // 左右边距40
      child: SizedBox(
        width: double.infinity, // 宽度占满父容器
        child: ElevatedButton(
          onPressed: _login, // 点击触发登录逻辑
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052D9), // 按钮背景色（蓝色）
            padding: const EdgeInsets.symmetric(vertical: 12), // 垂直内边距12
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // 圆角8
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3), // 加载状态显示进度条
                )
              : const Text('登录', // 正常状态显示按钮文字
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  /// 构建底部链接区域
  /// 包含"扫码登录"和"更多选项"（弹出菜单：注册账号、忘记密码）
  Widget _buildBottomLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // 水平居中
      children: [
        // "扫码登录"按钮
        TextButton(
          onPressed: () {}, // 暂未实现功能
          child: const Text('扫码登录',
              style: TextStyle(color: Color(0xFF5B8EDC), fontSize: 14)),
        ),
        const Text('|',
            style: TextStyle(color: Colors.white24, fontSize: 14)), // 分隔线

        // "更多选项"弹出菜单
        PopupMenuButton<String>(
          color: const Color(0xFF2E2E2E), // 菜单背景色（深色）
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)), // 菜单圆角
          onSelected: (value) {
            // 菜单选项选中回调
            if (value == 'register') {
              // 跳转到注册页面
              Navigator.pushNamed(context, '/register');
            } else if (value == 'forgot_password') {
              print('忘记密码 tapped'); // 忘记密码逻辑（暂未实现）
            }
          },
          // 菜单选项列表
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            _buildPopupMenuItem(value: 'register', text: '注册账号'), // 注册账号选项
            _buildPopupMenuItem(
                value: 'forgot_password', text: '忘记密码'), // 忘记密码选项
          ],
          // 菜单按钮样式（显示"更多选项"文字）
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('更多选项',
                style: TextStyle(color: Color(0xFF5B8EDC), fontSize: 14)),
          ),
        ),
      ],
    );
  }

  /// 辅助方法：构建弹出菜单的选项条目
  /// [value]：选项标识（用于onSelected回调判断）
  /// [text]：选项显示文字
  PopupMenuItem<String> _buildPopupMenuItem(
      {required String value, required String text}) {
    return PopupMenuItem<String>(
      value: value, // 选项标识
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14), // 选项文字样式
        ),
      ),
    );
  }
}
