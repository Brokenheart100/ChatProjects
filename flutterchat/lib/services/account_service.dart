import 'dart:convert';
import 'package:flutterchat/models/saved_account.dart'; // 引入账户模型类
import 'package:shared_preferences/shared_preferences.dart'; // 用于本地数据存储

class AccountService {
  // 存储已保存账户列表的 SharedPreferences 键名
  static const _kSavedAccountsKey = 'saved_accounts';

  /// 加载所有已保存的账户
  /// 从 SharedPreferences 中读取并解析账户列表JSON数据
  /// 返回值：包含所有已保存账户的列表，无数据时返回空列表
  Future<List<SavedAccount>> loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kSavedAccountsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      // 将JSON列表转换为 SavedAccount 实例列表
      return jsonList.map((json) => SavedAccount.fromJson(json)).toList();
    }
    return [];
  }

  /// 私有方法：保存账户列表到本地
  /// 将账户列表转换为JSON字符串并存储到 SharedPreferences
  /// 参数：需要保存的账户列表
  Future<void> _saveAccounts(List<SavedAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    // 将账户列表转换为可序列化的JSON列表
    final jsonString = jsonEncode(accounts.map((acc) => acc.toJson()).toList());
    await prefs.setString(_kSavedAccountsKey, jsonString);
  }

  /// 保存或更新一个账户
  /// 根据用户名判断账户是否已存在：存在则更新信息，不存在则新增
  /// 参数：需要保存或更新的账户实例
  Future<void> saveOrUpdateAccount(SavedAccount newAccount) async {
    final accounts = await loadSavedAccounts();
    // 查找账户在列表中的索引（通过用户名匹配）
    final index =
        accounts.indexWhere((acc) => acc.username == newAccount.username);

    if (index != -1) {
      // 若存在，更新该位置的账户信息
      accounts[index] = newAccount;
    } else {
      // 若不存在，添加新账户到列表
      accounts.add(newAccount);
    }
    // 保存更新后的账户列表
    await _saveAccounts(accounts);
  }

  /// 更新账户的"自动登录"状态
  /// 核心逻辑：确保系统中只有一个账户能启用自动登录
  /// 参数：
  ///   - targetAccount：需要更新自动登录状态的目标账户
  ///   - isEnabled：是否启用自动登录（true启用，false禁用）
  Future<void> updateAutoLogin(
      SavedAccount targetAccount, bool isEnabled) async {
    final accounts = await loadSavedAccounts();
    for (var account in accounts) {
      if (account.username == targetAccount.username) {
        // 更新目标账户的自动登录状态
        account.autoLoginEnabled = isEnabled;
      } else {
        // 当启用目标账户的自动登录时，自动禁用其他所有账户的自动登录
        if (isEnabled) {
          account.autoLoginEnabled = false;
        }
      }
    }
    // 保存更新后的账户列表
    await _saveAccounts(accounts);
  }

  /// 获取启用"自动登录"的账户
  /// 从已保存的账户中查找第一个启用自动登录的账户
  /// 返回值：找到的账户实例，无符合条件的账户时返回null
  Future<SavedAccount?> getAccountForAutoLogin() async {
    final accounts = await loadSavedAccounts();
    try {
      // 查找并返回第一个启用自动登录的账户
      return accounts.firstWhere((acc) => acc.autoLoginEnabled);
    } catch (e) {
      // 当列表中没有符合条件的账户时（抛异常），返回null
      return null;
    }
  }
}
