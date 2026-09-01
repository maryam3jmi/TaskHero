import 'package:flutter/material.dart';
import 'package:taskhero/services/conn.dart'; 
import 'package:taskhero/services/session.dart';
import 'package:taskhero/parent/addtask.dart';

// ========================================================
// الشاشة الأولى: تعرض قائمة الأطفال (تفتح عند الضغط من السايد منيو)
// ========================================================
class ManageTaskScreen extends StatefulWidget {
  const ManageTaskScreen({super.key});

  @override
  State<ManageTaskScreen> createState() => _ManageTaskScreenState();
}

class _ManageTaskScreenState extends State<ManageTaskScreen> {
  List<Map<String, dynamic>> childrenList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChildrenData();
  }

  // جلب الأطفال المعتمد على نفس منطق صفحتك الرئيسية الناجح
  Future<void> _fetchChildrenData() async {
    final parentId = AppSession.parentId;
    if (parentId == null) return;

    try {
      setState(() => isLoading = true);

      
      final familyResponse = await supabase
          .from('Family')
          .select('child_id')
          .eq('parent_id', parentId);

      List<dynamic> familyList = familyResponse as List;
      List<String> childIds = familyList.map((e) => e['child_id'].toString()).toList();

      List<Map<String, dynamic>> tempChildren = [];

      
      for (String childId in childIds) {
        final childResponse = await supabase
            .from('child')
            .select('child_name, child_pic')
            .eq('child_id', childId);

        if (childResponse.isEmpty) continue;

        tempChildren.add({
          "child_id": childId,
          "child_name": childResponse[0]['child_name'] ?? 'Unknown',
          "child_pic": childResponse[0]['child_pic'] ?? '',
        });
      }

      if (mounted) {
        setState(() {
          childrenList = tempChildren;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("ERROR FETCHING CHILDREN: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA6CBE3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manege Task", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'ADLaM Display'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.black, size: 30),
            onPressed: () {},
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
                  child: Text(
                    "My Children's",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'ADLaM Display'),
                  ),
                ),
                Expanded(
                  child: childrenList.isEmpty
                      ? const Center(child: Text("No children found.", style: TextStyle(fontFamily: 'ADLaM Display', color: Colors.white)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          itemCount: childrenList.length,
                          itemBuilder: (context, index) {
                            final child = childrenList[index];
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                leading: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: (child['child_pic'] != null && child['child_pic'].toString().isNotEmpty)
                                        ? NetworkImage(child['child_pic'])
                                        : null,
                                    child: (child['child_pic'] == null || child['child_pic'].toString().isEmpty)
                                        ? const Icon(Icons.person, size: 30, color: Colors.grey)
                                        : null,
                                  ),
                                ),
                                title: Text(
                                  child['child_name'],
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ADLaM Display'),
                                ),
                                trailing: const Icon(Icons.reply, color: Colors.blue, size: 30), // السهم الأزرق للانتقال
                                onTap: () {
                                  // نمرر البيانات الحقيقية والكاملة للطفل عند الضغط عليه هنا
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChildTasksPage(
                                        childId: child['child_id'],
                                        childName: child['child_name'],
                                        childPic: child['child_pic'],
                                      ),
                                    ),
                                  ).then((_) => _fetchChildrenData()); 
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}



// ========================================================
class ChildTasksPage extends StatefulWidget {
  final String childId; 
  final String childName; 
  final String? childPic;

  const ChildTasksPage({
    super.key, 
    required this.childId,
    required this.childName,
    this.childPic,
  });

  @override
  State<ChildTasksPage> createState() => _ChildTasksPageState();
}

class _ChildTasksPageState extends State<ChildTasksPage> {
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  
  Future<void> _fetchTasks() async {
    final parentId = AppSession.parentId;
    if (parentId == null) return;

    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('tasks')
          .select('*')
          .eq('assigned_to_child', widget.childId)
          .eq('created_by_parent', parentId);
          
      setState(() {
        tasks = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("ERROR FETCHING TASKS: $e");
    }
  }

  // حذف التاسك بالـ Task_id
  Future<void> _deleteTask(int taskId) async {
    try {
      await supabase
          .from('tasks')
          .delete()
          .eq('Task_id', taskId);
          
      _fetchTasks(); 
    } catch (e) {
      debugPrint("ERROR DELETING TASK: $e");
    }
  }

  
  void _showDeleteDialog(int taskId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.black, size: 24),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Are you sure you want to\ndelete this task?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'ADLaM Display'
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteTask(taskId);
                      },
                      child: const Text("Yes", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'ADLaM Display')),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("NO", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'ADLaM Display')),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA6CBE3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manege Task", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'ADLaM Display'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.black, size: 30),
            onPressed: () {},
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: const Color(0xFFFFD54F),
                    backgroundImage: (widget.childPic != null && widget.childPic!.isNotEmpty)
                        ? NetworkImage(widget.childPic!)
                        : null,
                    child: (widget.childPic == null || widget.childPic!.isEmpty)
                        ? const Icon(Icons.face, size: 45, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                
                Text(
                  "${widget.childName}’s Task’s",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ADLaM Display'),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(child: Text("No tasks found for this child.", style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'ADLaM Display')))
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 15, right: 25),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              child: Row(
                                children: [
                                 
                                  GestureDetector(
                                    onTap: () => _showDeleteDialog(task['Task_id']),
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Icon(
                                        Icons.delete_outline, 
                                        color: Color(0xFFB39DDB), 
                                        size: 35,
                                      ),
                                    ),
                                  ),
                                  
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD54F),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_box_outline_blank, color: Colors.white, size: 24),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Text(
                                              task['Task_title'] ?? '',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ADLaM Display'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
               Padding(
  padding: const EdgeInsets.only(bottom: 20),
  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTaskScreen(parentId: AppSession.parentId!),
        ),
      ).then((_) => _fetchTasks()); 
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.add, color: Colors.black, size: 35),
    ),
  ),
), 
                
              ],
            ),
    );
  }
}