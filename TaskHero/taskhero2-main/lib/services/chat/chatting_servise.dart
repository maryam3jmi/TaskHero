import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskhero/services/session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//changed supabase name
final supabase1 = Supabase.instance.client;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String parentId, String childId) {
    return parentId.compareTo(childId) > 0
        ? parentId + childId
        : childId + parentId;
  }

  Future<void> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    final senderId = AppSession.userId;
    if (senderId == null) return;

    String parentId = AppSession.userRole == "parent"
        ? senderId
        : AppSession.parentId!;

    String childId = AppSession.userRole == "child" ? senderId : receiverId;

    String chatId = getChatId(parentId, childId);

    await _firestore.collection("chats").doc(chatId).collection("messages").add(
      {
        "senderId": senderId,
        "receiverId": receiverId,

        "participants": [parentId, childId],

        "message": message,
        "timestamp": FieldValue.serverTimestamp(),

        "isRead": false,
      },
    );
    ///////////new notification part
    try {
      // decide who to query
      final table = AppSession.userRole == "child" ? 'parent' : 'child';
      final idColumn = AppSession.userRole == "child"
          ? 'parent_id'
          : 'child_id';

      final receiver = await supabase1
          .from(table)
          .select('fcm_token')
          .eq(idColumn, receiverId)
          .single();

      final token = receiver['fcm_token'];

      if (token != null) {
        await supabase1.from('notifications').insert({
          'receiver_id': receiverId,
          //'family_id': family_id,
          'title': 'New Message',
          'content': 'You received a new message',
          'type': 'message',
          'is_read': false,
          'sender_id': AppSession.userId, //new
          'sender_name': AppSession.username, //
        }); //inser message in notification table
        await supabase1.functions.invoke(
          //notification
          'send-notification',
          body: {'token': token, 'title': 'New Message', 'body': message},
        );
      }
    } catch (e) {
      print("Notification error: $e");
    }
    ///////////////end
    ///
  }

  Stream<QuerySnapshot> getMessages(String parentId, String childId) {
    String chatId = getChatId(parentId, childId);

    return _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}
