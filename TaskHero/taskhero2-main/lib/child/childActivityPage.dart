import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskhero/services/session.dart';
import 'package:taskhero/chat_page.dart';

final supabase = Supabase.instance.client;

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final data = await getNotifications();

    setState(() {
      notifications = data;
      loading = false;
    });
  }

  Future<void> handleNotificationTap(dynamic item) async {
    final type = item['type'];

    if (type == 'message') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            receiverId: item['sender_id'],
            receiverName: item['sender_name'],
          ),
        ),
      );
    }
    // =========================
    // REWARD NOTIFICATION
    // =========================
    else if (type == 'reward') {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => RewardPage(),
      //   ),
      // );
    }

    await supabase
        .from('notifications')
        .delete()
        .eq('notifications_id', item['notifications_id']);

    loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA9CDE3),

      appBar: AppBar(
        title: const Text("Activity"),
        backgroundColor: const Color(0xFFA9CDE3),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(
              child: Text("No Activity", style: TextStyle(fontSize: 18)),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];

                return InkWell(
                  onTap: () => handleNotificationTap(item),

                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFEAF6FF),
                          child: Icon(Icons.notifications),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                item['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(item['content'] ?? ''),

                              const SizedBox(height: 6),

                              Text(
                                item['created_date']?.toString() ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

Future<List<dynamic>> getNotifications() async {
  final data = await supabase
      .from('notifications')
      .select()
      .eq('receiver_id', AppSession.userId!)
      .order('created_date', ascending: false);

  return data;
}
