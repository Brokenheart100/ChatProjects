import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _apiService = ApiService(); // 创建服务实例
  bool _isLoading = false; // 用于控制加载状态

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

// 注册逻辑
  Future<void> _register() async {
    if (_isLoading) return; // 防止重复点击

    setState(() => _isLoading = true);

    try {
      await _apiService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      // 注册成功
      _showSnackBar('注册成功！请返回登录。', isError: false);
      // 可选：2秒后自动返回登录页
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (e) {
      // 注册失败
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 显示提示信息
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DragToMoveArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                Color(0xFF3C3A5A),
                Color(0xFF2C2B3D),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildTitleBar(context), // 标题栏，包含返回按钮
              const SizedBox(height: 30),
              const Text(
                '创建您的账号',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              _buildInputField(_usernameController, '输入用户名'),
              const SizedBox(height: 15),
              _buildInputField(_emailController, '输入邮箱'),
              const SizedBox(height: 15),
              _buildInputField(_passwordController, '输入密码', isPassword: true),
              const SizedBox(height: 15),
              _buildInputField(_confirmPasswordController, '确认密码',
                  isPassword: true),
              const SizedBox(height: 30),
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 构建带返回按钮的标题栏
  Widget _buildTitleBar(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.transparent,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pop(), // 点击返回上一页
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }

  // 构建输入框 (与登录页样式相同)
  Widget _buildInputField(TextEditingController controller, String hintText,
      {bool isPassword = false}) {
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
        ),
      ),
    );
  }

  // 构建注册按钮
  Widget _buildRegisterButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _register, // <-- 调用注册方法
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
              : const Text('注册',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
