// 文件: lib/widgets/friend_request_list.dart

import 'package:flutter/material.dart';
import 'package:flutterchat/models/friend_request.dart';
import 'package:flutterchat/services/api_service.dart';

class FriendRequestList extends StatefulWidget {
  const FriendRequestList({super.key});

  @override
  State<FriendRequestList> createState() => _FriendRequestListState();
}

class _FriendRequestListState extends State<FriendRequestList> {
  final _apiService = ApiService();
  late Future<List<FriendRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _apiService.getPendingFriendRequests();
  }

  void _acceptRequest(FriendRequest request) async {
    try {
      await _apiService.acceptFriendRequest(request.requestId);
      _refreshList();
    } catch (e) {/* ... show error */}
  }

  void _rejectRequest(FriendRequest request) async {
    try {
      await _apiService.rejectFriendRequest(request.requestId);
      _refreshList();
    } catch (e) {/* ... show error */}
  }

  void _refreshList() {
    setState(() {
      _requestsFuture = _apiService.getPendingFriendRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FriendRequest>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('没有新的好友请求', style: TextStyle(color: Colors.white54)));
        }

        final requests = snapshot.data!;
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: (request.senderAvatarUrl != null)
                    ? NetworkImage(
                        _apiService.getFullAvatarUrl(request.senderAvatarUrl))
                    : null,
              ),
              title: Text(request.senderName,
                  style: const TextStyle(color: Colors.white)),
              subtitle: const Text('请求添加你为好友',
                  style: TextStyle(color: Colors.white70)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _rejectRequest(request),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700),
                    child: const Text('拒绝'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _acceptRequest(request),
                    child: const Text('接受'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
