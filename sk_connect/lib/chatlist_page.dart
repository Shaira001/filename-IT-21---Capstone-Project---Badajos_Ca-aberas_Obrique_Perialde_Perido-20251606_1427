import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sk_connect/chat_class.dart';
import 'package:sk_connect/chatterScreen.dart';
import 'package:sk_connect/client_class.dart';
import 'package:sk_connect/database_helper.dart';
import 'package:sk_connect/utils.dart';

class ChatList extends StatefulWidget {
  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  // Stream of chats for the current user
  Stream<List<Chat>> get userChatsStream => getUserChatsStream(curClient.uid);

  // Helper to fetch the other user (not the current user) in a one-on-one chat
  Future<Client?> _getOtherUserTracker(Chat chat) async {
    String uid = chat.holdersUid[0] == curClient.uid
        ? chat.holdersUid[1]
        : chat.holdersUid[0];
    return await getClient(uid);
  }

  // Builds the scrolling list of chats (including the Admin Support entry at the top)
  Widget _buildChatList() {
    const String adminUid = "PC7Bw2Bzh6SMSm7msZJ1q0yGIqC2";

    return StreamBuilder<List<Chat>>(
      stream: userChatsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading chats",
              style: TextStyle(color: Colors.blue.shade800),
            ),
          );
        }

        final chats = snapshot.data ?? [];
        return ListView.builder(
          itemCount: chats.length + 1,
          itemBuilder: (context, index) {
            // First item: Admin Support
            if (index == 0) {
              return Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400,
                      Colors.blue.shade600,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.support_agent,
                      color: Colors.blue.shade700,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    "Admin Support",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Get help from our team",
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                  onTap: () async {
                    // Change here: use non‐nullable Chat
                    Chat adminChat = chats.firstWhere(
                      (c) => c.holdersUid.contains(adminUid),
                      orElse: () => Chat.empty(),
                    );

                    if (adminChat.key.isEmpty) {
                      // If no existing admin chat, create a new one
                      adminChat = Chat(
                        key: '',
                        holdersUid: [curClient.uid, adminUid],
                        lastMessage: '',
                        timestamp: DateTime.now(),
                        messages: [],
                        hasRead: false,
                      );

                      final chatID = await addChat(adminChat);
                      if (chatID == null) return;
                      adminChat.key = chatID;
                    }

                    // Now adminChat is guaranteed non‐nullable
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatterScreen(chat: adminChat, chatterName: "Admin"),
                        ),
                      );
                    }
                  },
                ),
              );
            }

            // All other chats (excluding Admin)
            final chat = chats[index - 1];
            if (chat.holdersUid.contains(adminUid)) {
              // Skip re‐rendering a second Admin tile
              return SizedBox.shrink();
            } else {
              return FutureBuilder<Client?>(
                future: _getOtherUserTracker(chat),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerChatItem();
                  }

                  if (!userSnapshot.hasData) {
                    return SizedBox.shrink();
                  }

                  final client = userSnapshot.data!;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: (client.profilePicture.isNotEmpty)
                            ? MemoryImage(base64Decode(client.profilePicture))
                            : null,
                        child: (client.profilePicture.isEmpty)
                            ? Text(
                                client.fullName.isNotEmpty
                                    ? client.fullName[0]
                                    : '?',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        client.fullName,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        chat.lastMessage,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatTimeDifference(chat.timestamp),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          if (!chat.hasRead)
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatterScreen(
                              chat: chat,
                              chatterName: client.fullName,
                            ),
                          ),
                        );
                      },
                      onLongPress: () async {
                        final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text("Delete Chat"),
                                content:
                                    Text("Are you sure you want to delete this chat?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                      deleteChat(chat.key);
                                    },
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (confirm) await deleteChat(chat.key);
                      },
                    ),
                  );
                },
              );
            }
          },
        );
      },
    );
  }

  // A placeholder shimmer widget while loading a chat row
  Widget _buildShimmerChatItem() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
        ),
        title: Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Container(
          height: 14,
          width: 180,
          margin: EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        trailing: Container(
          height: 14,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.blue.shade400,
      ),
      body: _buildChatList(),
    );
  }
}
