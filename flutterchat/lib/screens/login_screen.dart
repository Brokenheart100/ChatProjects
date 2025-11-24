import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 引入 Riverpod
import 'package:flutterchat/models/saved_account.dart';
import 'package:flutterchat/providers/services_provider.dart'; // 引入 Provider
import 'package:flutterchat/services/account_service.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:window_manager/window_manager.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // 我们依然可以使用局部的 AccountService，因为它不涉及全局状态共享
  final _accountService = AccountService();

  bool _isLoading = false;
  bool _isChecked = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  List<SavedAccount> _savedAccounts = [];
  SavedAccount? _selectedAccount;

  @override
  void initState() {
    super.initState();
    // _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    final accounts = await _accountService.loadSavedAccounts();
    setState(() {
      _savedAccounts = accounts;
      _selectedAccount = accounts.isNotEmpty ? accounts.first : null;
    });
  }

  Future<void> _login() async {
    if (_isLoading) return;

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('请输入用户名和密码', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 核心修改：使用 Riverpod 的 apiServiceProvider
      final apiService = ref.read(apiServiceProvider);

      final authResponse = await apiService.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      // 核心修改：登录成功后，更新全局 CurrentUser 状态
      ref.read(currentUserProvider.notifier).setUser(authResponse);

      final accountToSave = SavedAccount(
        username: authResponse.username,
        token: authResponse.token,
        avatarUrl: authResponse.avatarUrl,
        autoLoginEnabled: false,
      );
      await _accountService.saveOrUpdateAccount(accountToSave);

      if (!mounted) return;
      _passwordController.clear();
      _usernameController.clear();

      // 导航到主页 (不需要再传参了，因为已经存到 Provider 里了)
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e, stackTrace) {
      logger.e('登录失败！', error: e, stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar(e.toString(), isError: true);
      }
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
    ref.read(apiServiceProvider);

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
              const SizedBox(height: 15),
              // 这里需要把 apiService 传给子组件或者子组件自己获取，
              // 但为了简单，我们假设 CustomCircleAvatar 内部已经处理好了 URL
              _buildMultiAccountDisplay(),
              const SizedBox(height: 15),
              _buildInputField(_usernameController, '输入Username',
                  hasDropdown: true),
              const SizedBox(height: 15),
              _buildInputField(_passwordController, '输入Password',
                  isPassword: true),
              const SizedBox(height: 20),
              _buildAgreementCheckbox(),
              const SizedBox(height: 20),
              _buildLoginButton(),
              const Spacer(),
              _buildBottomLinks(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ... 请把之前的 _buildMultiAccountDisplay, _buildInputField 等私有方法全部复制过来 ...

  Widget _buildMultiAccountDisplay() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CustomCircleAvatar(
              avatarUrl: _selectedAccount?.avatarUrl,
              radius: 45,
            ),
            Positioned(
              top: -10,
              right: -40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(77),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('多账号登录',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_selectedAccount != null)
          Text(
            _selectedAccount!.username,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        const SizedBox(height: 20),
        if (_selectedAccount != null) _buildAutoLoginCheckbox(),
        const SizedBox(height: 30),
        _buildAccountAvatarList(),
      ],
    );
  }

  Widget _buildAutoLoginCheckbox() {
    return GestureDetector(
      onTap: () async {
        final newValue = !_selectedAccount!.autoLoginEnabled;
        await _accountService.updateAutoLogin(_selectedAccount!, newValue);
        await _loadSavedAccounts();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1.5),
              color: _selectedAccount!.autoLoginEnabled
                  ? Colors.blue
                  : Colors.transparent,
            ),
            child: _selectedAccount!.autoLoginEnabled
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          const Text('自动登录',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAccountAvatarList() {
    // 获取 apiService 用于生成完整头像 URL
    final apiService = ref.read(apiServiceProvider);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: _savedAccounts.length + 1,
        itemBuilder: (context, index) {
          if (index == _savedAccounts.length) {
            return _buildAddAccountButton();
          }
          final account = _savedAccounts[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAccount = account;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedAccount?.username == account.username
                          ? Colors.blue
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: (account.avatarUrl != null &&
                          account.avatarUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          // 使用 apiService 生成完整 URL
                          imageUrl:
                              apiService.getFullAvatarUrl(account.avatarUrl),
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              Container(color: Colors.grey),
                        )
                      : Container(
                          color: Colors.grey.shade700,
                          child:
                              const Icon(Icons.person, color: Colors.white70),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddAccountButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/register');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(77),
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: Colors.grey.shade600, width: 1),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      height: 40,
      color: Colors.transparent,
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

  Widget _buildAgreementCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                    recognizer: TapGestureRecognizer()..onTap = () {},
                  ),
                  const TextSpan(text: '和'),
                  TextSpan(
                    text: 'QQ隐私保护指引',
                    style: const TextStyle(color: Color(0xFF5B8EDC)),
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
          onPressed: _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052D9),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
        PopupMenuButton<String>(
          color: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onSelected: (value) {
            if (value == 'register') {
              Navigator.pushNamed(context, '/register');
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            _buildPopupMenuItem(value: 'register', text: '注册账号'),
            _buildPopupMenuItem(value: 'forgot_password', text: '忘记密码'),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('更多选项',
                style: TextStyle(color: Color(0xFF5B8EDC), fontSize: 14)),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      {required String value, required String text}) {
    return PopupMenuItem<String>(
      value: value,
      child: Center(
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }
}
