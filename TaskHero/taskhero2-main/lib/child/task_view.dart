import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import '../services/session.dart';
import '../services/task_reset_service.dart'; // <-- ADD THIS IMPORT

class ChildTasksPage extends StatefulWidget {
  const ChildTasksPage({super.key});

  @override
  State<ChildTasksPage> createState() => _ChildTasksPageState();
}

class _ChildTasksPageState extends State<ChildTasksPage> {
  final supabase = Supabase.instance.client;

  List<Task> tasks = [];

  String childName = "";
  String childPic = "";

  @override
  void initState() {
    super.initState();
    loadChildData();
  }

  /// LOAD CHILD + TASKS
  Future<void> loadChildData() async {
    final childId = AppSession.childId;

    if (childId == null) return;

    try {
      // RESET FIRST in DB before fetching — so we always read fresh state
      await TaskResetService.resetRecurringTasksForChild(childId);

      /// FETCH CHILD INFO
      final childRes = await supabase
          .from('child')
          .select()
          .eq('child_id', childId)
          .single();

      /// FETCH TASKS (after reset, so statuses are correct)
      final taskRes = await supabase
          .from('tasks')
          .select(
            'Task_id, Task_title, Task_status, assigned_to_child, created_date, due_date, Cash_amount, point_amount, task_repet, completed_at, completion_history',
          )
          .eq('assigned_to_child', childId);

      final fetchedTasks = taskRes
          .map<Task>((task) => Task.fromMap(task))
          .toList();

      setState(() {
        childName = childRes['child_name'] ?? "";
        childPic = childRes['child_pic'] ?? "";
        tasks = fetchedTasks;
      });
    } catch (e) {
      debugPrint("Error loading child data: $e");
    }
  }

  
  bool shouldShowTask(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (task.dueDate == null) return true;

    
final initialDueDate = DateTime(
  task.dueDate!.year,
  task.dueDate!.month,
  task.dueDate!.day,
);

    /// DAILY LOGIC
    if (task.repeat == 'Daily') {
     
      return !today.isAfter(initialDueDate);
    }

   
    if (today.isBefore(initialDueDate)) {
      return false;
    }

    if (task.repeat == 'Weekly') {
      // Keep repeating on the same day of the week as the initial due date
      return now.weekday == initialDueDate.weekday;
    }

    if (task.repeat == 'Monthly') {
      // Handle month-end roll-overs safely (e.g., if target day is 31st but month only has 30 days)
      final lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
      final targetDay = initialDueDate.day > lastDayOfCurrentMonth 
          ? lastDayOfCurrentMonth 
          : initialDueDate.day;

      return now.day == targetDay;
    }

    return true;
  }

  /// TOGGLE TASK
  void toggleTask(Task task) async {
    final isCompleting = task.status != 'completed';
    final childId = AppSession.childId;
    final taskPoints = task.pointAmount ?? 0;

    if (isCompleting) {
      final updatedHistory = [
        ...task.completionHistory,
        DateTime.now().toIso8601String(),
      ];

      await supabase
          .from('tasks')
          .update({
            'Task_status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'completion_history': updatedHistory,
          })
          .eq('Task_id', task.id);

      if (childId != null && taskPoints > 0) {
        final childRes = await supabase
            .from('child')
            .select('child_point')
            .eq('child_id', childId)
            .single();

        final currentPoints = (childRes['child_point'] as num?)?.toInt() ?? 0;

        await supabase
            .from('child')
            .update({'child_point': currentPoints + taskPoints})
            .eq('child_id', childId);
      }
    } else {
      final updatedHistory = [...task.completionHistory];
      if (updatedHistory.isNotEmpty) updatedHistory.removeLast();

      await supabase
          .from('tasks')
          .update({
            'Task_status': 'pending',
            'completed_at': null,
            'completion_history': updatedHistory,
          })
          .eq('Task_id', task.id);

      if (childId != null && taskPoints > 0) {
        final childRes = await supabase
            .from('child')
            .select('child_point')
            .eq('child_id', childId)
            .single();

        final currentPoints = (childRes['child_point'] as num?)?.toInt() ?? 0;

        await supabase
            .from('child')
            .update({
              'child_point': (currentPoints - taskPoints).clamp(0, 999999),
            })
            .eq('child_id', childId);
      }
    }

    setState(() {
      tasks = tasks.map((t) {
        if (t.id != task.id) return t;
        return Task(
          id: t.id,
          title: t.title,
          status: isCompleting ? 'completed' : 'pending',
          assignedTo: t.assignedTo,
          createdDate: t.createdDate,
          dueDate: t.dueDate,
          cashAmount: t.cashAmount,
          pointAmount: t.pointAmount,
          repeat: t.repeat,
          completedAt: isCompleting ? DateTime.now() : null,
          completionHistory: isCompleting
              ? [...task.completionHistory, DateTime.now().toIso8601String()]
              : task.completionHistory.isNotEmpty
              ? task.completionHistory.sublist(
                  0,
                  task.completionHistory.length - 1,
                )
              : [],
        );
      }).toList();
    });

    if (isCompleting) {
      if (taskPoints > 0) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("🎉 Great Job!"),
            content: Text(
              "You earned ${task.pointAmount} points!",
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Yay!"),
              ),
            ],
          ),
        );
      }
      if ((task.cashAmount ?? 0) > 0) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("💰 Awesome!"),
            content: Text(
              "You earned ${task.cashAmount} SAR!",
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cool!"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
  final completed = tasks
    .where((t) => t.status == 'completed' && shouldShowTask(t))
    .toList();

final pending = tasks
    .where((t) => t.status != 'completed' && shouldShowTask(t))
    .toList();

/// ONLY TASKS CURRENTLY VISIBLE TO THE CHILD
final visibleTasks = [
  ...pending,
  ...completed,
];

final progress = visibleTasks.isEmpty
    ? 0.0
    : completed.length / visibleTasks.length;

    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        209,
        231,
        243,
      ).withOpacity(0.90),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              /// TOP BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },

                        child: Container(
                          padding: const EdgeInsets.all(8),

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.arrow_back,
                            size: 22,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi, $childName!",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "You have ${pending.length} tasks today",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  CircleAvatar(
                    radius: 20,
                    backgroundImage: childPic.isNotEmpty
                        ? NetworkImage(childPic)
                        : null,
                    child: childPic.isEmpty ? const Icon(Icons.person) : null,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tasks Completed"),
                  Text(
  "${completed.length} of ${visibleTasks.length} tasks",
),
                ],
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Progress",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
  "${completed.length}/${visibleTasks.length}",
  style: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
)
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "To-Do",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...List.generate(pending.length, (index) {
                        final task = pending[index];
                        final isRed = index % 2 == 0;
                        return buildTaskCard(
                          task,
                          isRed
                              ? const Color.fromARGB(255, 246, 147, 139)
                              : const Color.fromARGB(255, 247, 238, 158),
                          false,
                        );
                      }),

                      const SizedBox(height: 20),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "All Done!",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      ...completed.map((task) {
                        return buildTaskCard(
                            task, const Color(0xFFDDF5E1), true);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTaskCard(Task task, Color color, bool done) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  task.repeat == "Daily"
                      ? Icons.today
                      : task.repeat == "Weekly"
                          ? Icons.calendar_view_week
                          : Icons.calendar_month,
                  size: 25,
                  color: const Color.fromARGB(255, 61, 61, 61),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          if ((task.pointAmount ?? 0) > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${task.pointAmount}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if ((task.pointAmount ?? 0) > 0 &&
                              (task.cashAmount ?? 0) > 0)
                            const SizedBox(width: 6),

                          if ((task.cashAmount ?? 0) > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.payments,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${task.cashAmount} SAR",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => toggleTask(task),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? Colors.green : Colors.white.withOpacity(0.6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: done
                  ? const Icon(Icons.verified, size: 18, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

