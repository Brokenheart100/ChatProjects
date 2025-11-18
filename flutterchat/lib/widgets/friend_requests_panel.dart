import 'package:flutter/material.dart';
import 'package:flutterchat/models/friend_request.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';

class FriendRequestsPanel extends StatefulWidget {
  const FriendRequestsPanel({super.key});

  @override
  State<FriendRequestsPanel> createState() => _FriendRequestsPanelState();
}

class _FriendRequestsPanelState extends State<FriendRequestsPanel> {
  final _apiService = ApiService();
  // 使用 FutureBuilder 来管理异步加载
  late Future<List<FriendRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    setState(() {
      _requestsFuture = _apiService.getPendingFriendRequests();
    });
  }

  Future<void> _handleRequest(String requestId, bool accept) async {
    try {
      if (accept) {
        await _apiService.acceptFriendRequest(requestId);
      } else {
        await _apiService.rejectFriendRequest(requestId);
      }
      // 操作成功后，刷新列表
      _loadRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF54514E),
      child: FutureBuilder<List<FriendRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('加载失败: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child:
                    Text('没有新的好友请求', style: TextStyle(color: Colors.white54)));
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                color: const Color(0xFF474542),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CustomCircleAvatar(
                      avatarUrl: request.senderAvatarUrl, radius: 24),
                  title: Text(request.senderName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('请求添加你为好友',
                      style: TextStyle(color: Colors.grey.shade400)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _handleRequest(request.requestId, false),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700),
                        child: const Text('拒绝'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            _handleRequest(request.requestId, true),
                        child: const Text('接受'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
