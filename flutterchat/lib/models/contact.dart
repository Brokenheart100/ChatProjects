import 'package:flutter/material.dart';

class Contact {
  final String avatar;
  final String name;
  final String qqNumber;
  final String statusText;
  final IconData statusIcon;
  final Color statusIconColor;
  final String gender;
  final int age;
  final String birthday;
  final String constellation;
  final String remark;
  final String groupName;
  final String signature;
  final List<String> photos;

  Contact({
    required this.avatar,
    required this.name,
    required this.qqNumber,
    required this.statusText,
    required this.statusIcon,
    required this.statusIconColor,
    required this.gender,
    required this.age,
    required this.birthday,
    required this.constellation,
    required this.remark,
    required this.groupName,
    required this.signature,
    required this.photos,
  });
}
