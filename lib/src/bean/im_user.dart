import 'dart:convert';

/// IM用户信息
class IMUser {
  /// 注册时返回的用户id。
  String? id;

  /// 联系人列表中用户id字段
  String? userId;

  /// 本地字段。 未读消息数，用于在聊天历史列表设置未读消息个数。
  int? unreadCount;

  /// "online":"是否在线（0：离线，1：在线）"
  int? online;

  String? companyId, account, password, username, headImg;

  IMUser({
    this.id,
    this.userId,
    this.companyId,
    this.account,
    this.password,
    this.username,
    this.unreadCount,
    this.headImg,
    this.online,
  });

  factory IMUser.fromJson(Map<String, dynamic> json) {
    return IMUser(
      id: json['id']?.toString(),
      userId: json['userId']?.toString(),
      online: json['online'],
      companyId: json['companyId'],
      account: json['account'],
      password: json['password'],
      username: json['username'],
      headImg: json['headImg'] ?? '',
      unreadCount: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'online': online,
      'companyId': companyId,
      'account': account,
      'password': password,
      'username': username,
      'headImg': headImg,
    };
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}
