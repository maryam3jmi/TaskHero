import 'package:flutter/material.dart';
import 'package:taskhero/parent/reportsfinal.dart';
import 'package:taskhero/services/conn.dart';
import 'package:taskhero/services/session.dart';
import 'package:taskhero/services/task_reset_service.dart'; // <-- ADD THIS IMPORT
import 'package:taskhero/splash_screen.dart';
import 'manage_children_page.dart';
import 'parent_chat_list_page.dart';
import 'manage_task_screen.dart';
import 'edit_profile_page.dart';
import 'package:taskhero/services/chat/chatting_servise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'help_center.dart';

class ParentProgressScreen extends StatefulWidget {
  const ParentProgressScreen({super.key});

  @override
  State<ParentProgressScreen> createState() => _ParentProgressScreenState();
}

class _ParentProgressScreenState extends State<ParentProgressScreen> {
  bool isMenuOpen = false;
  final ChatService _chatService = ChatService();

  bool hasUnreadMessages = false;
  bool isLoading = true;

  String parentName = "";
  String parentPic = "";

  List<Map<String, dynamic>> childrenData = [];

  @override
  void initState() {
    super.initState();
    fetchChildrenAndTasks();
    listenForMessages();
  }

  /// FETCH DATA
  Future<void> fetchChildrenAndTasks() async {
    final parentId = AppSession.parentId;

    if (parentId == null) return;

    try {
      // RESET ALL CHILDREN'S TASKS FIRST — writes correct state to DB
      // This means even if the child hasn't opened the app, the parent
      // sees accurate data and the DB is in sync.
      await TaskResetService.resetRecurringTasksForParent(parentId);

      /// FETCH PARENT
      final parentResponse = await supabase
          .from('parent')
          .select('parent_name, parent_pic')
          .eq('parent_id', parentId);

      if (parentResponse.isNotEmpty && mounted) {
        setState(() {
          parentName = parentResponse[0]['parent_name'] ?? "";
          parentPic = parentResponse[0]['parent_pic'] ?? "";
        });
      }

      /// FETCH FAMILY
      final familyResponse = await supabase
          .from('Family')
          .select('child_id')
          .eq('parent_id', parentId);

      List<String> childIds = (familyResponse as List)
          .map((e) => e['child_id'].toString())
          .toList();

      List<Map<String, dynamic>> tempChildren = [];

      for (String childId in childIds) {
        final childResponse = await supabase
            .from('child')
            .select('child_name')
            .eq('child_id', childId);

        if (childResponse.isEmpty) continue;

        // Fetch tasks AFTER reset — statuses are now accurate in the DB
        final tasksResponse = await supabase
            .from('tasks')
        .select(
  'Task_id, Task_title, Task_status, point_amount, '
  'task_repet, completed_at, completion_history, due_date'
)
            .eq('assigned_to_child', childId)
            .eq('created_by_parent', parentId);

        tempChildren.add({
          "child_id": childId,
          "child_name": childResponse[0]['child_name'],
          "tasks": tasksResponse,
        });
      }

      if (mounted) {
        setState(() {
          childrenData = tempChildren;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("ERROR: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  bool shouldShowTask(Map<String, dynamic> task) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final dueDateRaw = task['due_date'];

  if (dueDateRaw == null) return true;

  final parsedDueDate =
      DateTime.tryParse(dueDateRaw.toString());

  if (parsedDueDate == null) return true;

  final initialDueDate = DateTime(
    parsedDueDate.year,
    parsedDueDate.month,
    parsedDueDate.day,
  );

  final repeat = task['task_repet'];

  /// DAILY
  if (repeat == 'Daily') {
    return !today.isAfter(initialDueDate);
  }

  /// WEEKLY & MONTHLY
  if (today.isBefore(initialDueDate)) {
    return false;
  }

  /// WEEKLY
  if (repeat == 'Weekly') {
    return now.weekday == initialDueDate.weekday;
  }

  /// MONTHLY
  if (repeat == 'Monthly') {
    final lastDayOfCurrentMonth =
        DateTime(now.year, now.month + 1, 0).day;

    final targetDay =
        initialDueDate.day > lastDayOfCurrentMonth
            ? lastDayOfCurrentMonth
            : initialDueDate.day;

    return now.day == targetDay;
  }

  return true;
}

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double menuWidth = screenWidth * 0.65;

    return Scaffold(
      body: Stack(
        children: [
          /// MAIN CONTENT
          Container(
            color: const Color(0xFFA9CDE3),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SafeArea(
              child: Column(
                children: [
                  /// TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// CHAT
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ParentChatListPage(),
                                ),
                              );
                            },
                          ),
                          if (hasUnreadMessages)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),

                      /// MENU
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          setState(() {
                            isMenuOpen = true;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "My children's progress",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (childrenData.isEmpty)
                    const Expanded(
                      child: Center(child: Text("No children found")),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: childrenData.length,
                        itemBuilder: (context, index) {
                          return buildChildSection(childrenData[index]);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          /// SIDE MENU
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            right: isMenuOpen ? 0 : -menuWidth,
            top: 0,
            bottom: 0,
            width: menuWidth,
            child: _buildSideMenu(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    return Container(
      color: const Color(0xFFE0B93B),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    isMenuOpen = false;
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black,
                    backgroundImage: parentPic.isNotEmpty
                        ? NetworkImage(parentPic)
                        : null,
                    child: parentPic.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      parentName.isEmpty ? "Loading..." : parentName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Divider(),

            buildMenuItem(
              context,
              "Task Management",
              const ManageTaskScreen(),
            ),
            buildMenuItem(context, "Reports", const MockReportScreen()),
            buildMenuItem(
              context,
              "Manage children's accounts",
              ManageChildrenPage(parentId: AppSession.parentId!),
            ),
            buildMenuItem(
              context,
              "Manage my profile",
              const EditProfilePage(),
            ),

            const Spacer(),
            const Divider(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 10),
                    Text("Help", style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const Divider(), // اختياري: لإضافة خط فاصل بين المساعدة وتسجيل الخروج

// زر تسجيل الخروج الجديد الذي طلبته
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
  child: InkWell(
    onTap: () {
      // هنا استدعاء الـ Dialog الخاص بك
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Log Out"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                await supabase.auth.signOut();

                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SplashScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text("Yes"),
            ),
          ],
        ),
      );
    },
    child: const Row(
      children: [
        Icon(Icons.logout, color: Colors.red), // أيقونة تسجيل الخروج باللون الأحمر
        SizedBox(width: 10),
        Text(
          "Log Out", 
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
        ),
      ],
    ),
  ),
),
          ],
        ),
      ),
    );
  }

  Widget buildMenuItem(BuildContext context, String title, Widget? destination) {
    return InkWell(
      onTap: () {
        setState(() {
          isMenuOpen = false;
        });
        if (destination != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          ).then((_) {
            fetchChildrenAndTasks();
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Divider(),
          ],
        ),
      ),
    );
  }

  void listenForMessages() {
    FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: AppSession.userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              hasUnreadMessages = snapshot.docs.isNotEmpty;
            });
          }
        });
  }

  /// CHILD SECTION — now just reads DB directly, no client-side status overrides
Widget buildChildSection(Map<String, dynamic> child) {
  List tasks = (child["tasks"] as List)
      .where((task) => shouldShowTask(task))
      .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            child["child_name"],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                "No tasks assigned yet",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            )
          else
            SizedBox(
              height: 95,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  // Status is now accurate directly from DB — no client-side override needed
                  final completed = task['Task_status'] == 'completed';
                  return buildTaskBox(
  task['Task_title'] ?? "",
  completed,
  task['task_repet'] ?? '',
);
                },
              ),
            ),
        ],
      ),
    );
  }

Widget buildTaskBox(
  String title,
  bool completed,
  String repeat,
) {
  return Container(
    width: 100,
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: completed ? Colors.lightGreen[300] : Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          repeat,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}
}