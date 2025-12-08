import 'dart:convert'; // 导入JSON编解码库，用于账户数据的序列化和反序列化
import 'package:flutterchat/models/saved_account.dart'; // 导入账户模型类，定义SavedAccount的数据结构
import 'package:shared_preferences/shared_preferences.dart'; // 导入SharedPreferences库，用于本地持久化存储

/// 账户服务类，负责管理本地保存的账户信息（加载、保存、更新、删除、自动登录）
class AccountService {
  /// 存储在SharedPreferences中的账户列表键名（常量，不可修改）
  static const _kSavedAccountsKey = 'saved_accounts';

  /// 加载所有保存的账户，并按**最近登录时间倒序**排列
  ///
  /// 返回值：包含所有SavedAccount对象的列表，若没有保存的账户则返回空列表
  Future<List<SavedAccount>> loadSavedAccounts() async {
    // 获取SharedPreferences实例，用于访问本地存储
    final prefs = await SharedPreferences.getInstance();
    // 从本地存储中读取账户列表的JSON字符串
    final jsonString = prefs.getString(_kSavedAccountsKey);

    // 如果存在保存的账户数据
    if (jsonString != null) {
      // 将JSON字符串解码为动态类型列表
      final List<dynamic> jsonList = jsonDecode(jsonString);
      // 将动态类型列表转换为SavedAccount对象列表（通过fromJson工厂方法）
      final list = jsonList.map((json) => SavedAccount.fromJson(json)).toList();

      // 按登录时间倒序排序：最近登录的账户排在列表前面
      list.sort((a, b) => b.lastLoginAt.compareTo(a.lastLoginAt));
      return list;
    }
    // 若没有保存的账户，返回空列表
    return [];
  }

  /// 保存或更新账户信息
  ///
  /// 参数：
  /// - newAccount：待保存或更新的SavedAccount对象
  Future<void> saveOrUpdateAccount(SavedAccount newAccount) async {
    // 先加载所有已保存的账户
    final accounts = await loadSavedAccounts();

    // 移除旧的同名账户记录（若存在，实现"更新"逻辑）
    accounts.removeWhere((acc) => acc.username == newAccount.username);

    // 将新账户插入到列表头部（保证最新更新的账户在前面）
    accounts.insert(0, newAccount);

    // 处理自动登录逻辑：如果当前账户启用了自动登录，关闭其他所有账户的自动登录
    if (newAccount.autoLoginEnabled) {
      for (var acc in accounts) {
        // 仅保留当前账户的自动登录状态，其他账户禁用
        if (acc.username != newAccount.username) {
          acc.autoLoginEnabled = false;
        }
      }
    }

    // 将更新后的账户列表持久化到本地存储
    await _saveAccounts(accounts);
  }

  /// 移除指定用户名的账户
  ///
  /// 参数：
  /// - username：待移除账户的用户名
  Future<void> removeAccount(String username) async {
    // 加载所有已保存的账户
    final accounts = await loadSavedAccounts();
    // 移除匹配用户名的账户
    accounts.removeWhere((acc) => acc.username == username);
    // 将更新后的账户列表持久化到本地存储
    await _saveAccounts(accounts);
  }

  /// 私有方法：将账户列表序列化为JSON并保存到SharedPreferences
  ///
  /// 参数：
  /// - accounts：待保存的SavedAccount对象列表
  Future<void> _saveAccounts(List<SavedAccount> accounts) async {
    // 获取SharedPreferences实例
    final prefs = await SharedPreferences.getInstance();
    // 将账户列表转换为JSON字符串（每个SavedAccount通过toJson方法转换为Map）
    final jsonString = jsonEncode(accounts.map((acc) => acc.toJson()).toList());
    // 将JSON字符串保存到本地存储
    await prefs.setString(_kSavedAccountsKey, jsonString);
  }

  /// 获取启用了自动登录的账户
  /// 返回值：
  /// - 若存在启用自动登录的账户，返回该SavedAccount对象
  /// - 若不存在，返回null
  Future<SavedAccount?> getAccountForAutoLogin() async {
    // 加载所有已保存的账户
    final accounts = await loadSavedAccounts();
    try {
      // 查找第一个启用自动登录的账户（firstWhere找不到会抛出异常）
      return accounts.firstWhere((acc) => acc.autoLoginEnabled);
    } catch (e) {
      // 若没有找到启用自动登录的账户，返回null
      return null;
    }
  }
}
