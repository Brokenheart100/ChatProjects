import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // ✅ 引入 GoRouter
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
  bool _isLoading = false;
  String _loadingText = '正在注册...';
  XFile? _avatarFile;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    try {
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

  Future<void> _register() async {
    if (_isLoading) return;

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

      if (_avatarFile != null) {
        setState(() => _loadingText = '正在上传头像...');
        await apiService.getUploadUrl(_avatarFile!.name);
        avatarObjectKey =
            await apiService.uploadFileAndGetObjectKey(_avatarFile!);
      }

      setState(() => _loadingText = '正在创建账号...');
      await apiService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        avatarUrl: avatarObjectKey,
      );

      _showSnackBar('注册成功！请登录。', isError: false);

      // 等待一下让用户看到提示
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // ✅ 核心修复：使用 GoRouter 返回登录页
      context.pop();
    } catch (e) {
      logger.e('注册失败', error: e);
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
              colors: [Color(0xFF3C3A5A), Color(0xFF2C2B3D)],
            ),
          ),
          child: Column(
            children: [
              _buildTitleBar(),
              const SizedBox(height: 30),
              _buildAvatarPicker(),
              const SizedBox(height: 20),
              const Text('创建您的账号',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
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
        backgroundImage:
            _avatarFile != null ? FileImage(File(_avatarFile!.path)) : null,
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

  Widget _buildTitleBar() {
    return Container(
      height: 40,
      color: Colors.transparent,
      child: Row(
        children: [
          IconButton(
            // ✅ 核心修复：使用 GoRouter 返回
            icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 20),
            onPressed: () => context.pop(),
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
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052D9),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5)),
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
