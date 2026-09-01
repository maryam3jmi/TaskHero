import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskhero/chat_page.dart';
import 'package:taskhero/services/session.dart';

class ChildHomeTest extends StatefulWidget {
  const ChildHomeTest({super.key});

  @override
  State<ChildHomeTest> createState() => _ChildHomeTestState();
}

class _ChildHomeTestState extends State<ChildHomeTest> {
  final supabase = Supabase.instance.client;

  String? parentName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchParentName();
  }

  Future<void> fetchParentName() async {
    try {
      final data = await supabase
          .from('parent') // ⚠️ change if needed
          .select('parent_name') // ⚠️ change if needed
          .eq('parent_id', AppSession.parentId!)
          .maybeSingle();

      if (data != null) {
        parentName = data['parent_name'];
      }
    } catch (e) {
      print("❌ Error: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Child Home")),

      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : IconButton(
                icon: const Icon(Icons.message, size: 40),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        receiverId: AppSession.parentId!,
                        receiverName: parentName ?? "Parent",
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
