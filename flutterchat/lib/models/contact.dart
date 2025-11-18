/// 代表一个联系人的UI模型。
/// 它的数据源通常来自于API返回的模型（如 UserSearchResult），经过转换而来。
class Contact {
  final String id;
  final String name; // 对应 username
  final String? avatarUrl; // 完整的、可直接用于 NetworkImage 的 URL

  // remark 通常是用户自己设置的，可以与 name 不同
  final String remark;

  // --- 为详情页预留的可空字段 ---
  // 当后端API返回更多信息时，可以填充这些字段
  final String? qqNumber;
  final String? statusText;
  final String? gender;
  final int? age;
  final String? birthday;
  final String? constellation;
  final String? signature;
  final String? groupName;
  final List<String> photos;
  // --------------------------------

  Contact({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.remark = '',

    // 构造函数中的可选参数
    this.qqNumber,
    this.statusText,
    this.gender,
    this.age,
    this.birthday,
    this.constellation,
    this.signature,
    this.groupName,
    this.photos = const [], // 默认为一个空的列表
  });
}
