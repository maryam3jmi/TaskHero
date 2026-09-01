import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskhero/chat_page.dart';
import 'package:taskhero/services/session.dart';

class ParentChatListPage extends StatefulWidget {
  const ParentChatListPage({super.key});

  @override
  State<ParentChatListPage> createState() => _ParentChatListPageState();
}

class _ParentChatListPageState extends State<ParentChatListPage> {
  final supabase = Supabase.instance.client;

  List children = [];

  @override
  void initState() {
    super.initState();
    fetchChildren();
  }

  Future<void> fetchChildren() async {
    final data = await supabase
        .from('Family')
        .select('child_id')
        .eq('parent_id', AppSession.userId!);

    List temp = [];

    for (var item in data) {
      final childId = item['child_id'];

      final childData = await supabase
          .from('child')
          .select('child_name')
          .eq('child_id', childId)
          .maybeSingle();

      if (childData == null) continue;

      temp.add({"child_id": childId, "child_name": childData['child_name']});
    }

    setState(() {
      children = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFA9CDE3),
      appBar: AppBar(title: Text("Chats"), backgroundColor: Color(0xFFA9CDE3)),
      body: ListView.builder(
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9CF45),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),

                title: Text(
                  child['child_name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        receiverId: child['child_id'],
                        receiverName: child['child_name'],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
