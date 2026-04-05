import 'package:flutter/material.dart';

class ChatroomPage extends StatelessWidget {
  final String id;
  const ChatroomPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('聊天室 $id')),
      body: const Center(child: Text('聊天室')),
    );
  }
}
