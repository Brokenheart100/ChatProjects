import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
//  final _apiService = ApiService(); // 创建服务实例
  bool _isLoading = false; // 用于控制加载状态
  String _loadingText = '正在注册...';
  XFile? _avatarFile;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    try {
      // 从用户的相册中打开图片选择器
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _avatarFile = pickedFile;
        });
      }
    } catch (e) {
      _showSnackBar('选择图片失败: $e', isError: true);
    }
  }

// 注册逻辑
  Future<void> _register() async {
    if (_isLoading) return;

    // 前端验证
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('两次输入的密码不一致', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingText = '正在处理...';
    });

    String? avatarObjectKey;

    try {
      final apiService = ref.read(apiServiceProvider);
      // --- 步骤 1 & 2: 如果有头像，先上传头像 ---
      if (_avatarFile != null) {
        setState(() => _loadingText = '正在上传头像...');
        logger.i('Avatar selected, starting upload process...');

        // 1. 获取上传许可
        await apiService.getUploadUrl(_avatarFile!.name);
        avatarObjectKey =
            await apiService.uploadFileAndGetObjectKey(_avatarFile!);

        logger.i('Avatar upload completed. ObjectKey: $avatarObjectKey');
      }

      // --- 步骤 3: 提交注册信息到后端 ---
      setState(() => _loadingText = '正在创建账号...');
      logger.i('Calling register API...');

      await apiService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        avatarUrl: avatarObjectKey, // 将上传后得到的 objectKey 作为 avatarUrl
      );

      _showSnackBar('注册成功！请返回登录。', isError: false);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (e) {
      logger.e('Registration process failed', error: e);
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
              _buildAvatarPicker(),
              const SizedBox(height: 20),
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

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickAvatar,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: const Color(0xFF403E54),
        // 如果用户已经选择了图片，就显示图片预览
        backgroundImage:
            _avatarFile != null ? FileImage(File(_avatarFile!.path)) : null,
        // 如果没有选择图片，就显示一个图标和提示文字
        child: _avatarFile == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.white54, size: 30),
                  SizedBox(height: 4),
                  Text('选择头像',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              )
            : null,
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
              ? Row(
                  // 使用 Row 来显示加载圈和文字
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 12),
                    Text(_loadingText,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white)),
                  ],
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
