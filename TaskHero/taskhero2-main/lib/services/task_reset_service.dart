import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskResetService {
  static final _supabase = Supabase.instance.client;
/// Returns true if this task should be reset to pending RIGHT NOW.
  static bool shouldReset(Map<String, dynamic> task) {
    final status = task['Task_status'] as String?;
    final repeat = task['task_repet'] as String?;
    final completedAtRaw = task['completed_at'];
    final dueDateRaw = task['due_date']; // We need the due date to know the recurrence cycle

    if (status != 'completed') return false;
    if (completedAtRaw == null || dueDateRaw == null) return false;

    final completedAt = DateTime.tryParse(completedAtRaw.toString());
final parsedDueDate =
    DateTime.tryParse(dueDateRaw.toString());

if (parsedDueDate == null) return false;

final dueDate = DateTime(
  parsedDueDate.year,
  parsedDueDate.month,
  parsedDueDate.day,
);
    if (completedAt == null || dueDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedDay = DateTime(completedAt.year, completedAt.month, completedAt.day);
    final initialDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (repeat == 'Daily') {
      // Reset daily tasks on any new calendar day, provided the due date hasn't expired yet
      return today.isAfter(completedDay) && !today.isAfter(initialDueDate);
    }

    if (repeat == 'Weekly') {  if (now.weekday != initialDueDate.weekday) {
    return false;
  }

  return completedDay.isBefore(today);
}

    if (repeat == 'Monthly') {
      // Determine target calendar day, adjusting for varying month lengths
      final lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
      final targetDay = initialDueDate.day > lastDayOfCurrentMonth 
          ? lastDayOfCurrentMonth 
          : initialDueDate.day;

      final isTaskDayOfMonth = now.day == targetDay;
      return isTaskDayOfMonth && today.isAfter(completedDay);
    }

    return false;
  }

  /// Resets all eligible tasks in the DB for a given child.
  /// Call this from BOTH the child screen and the parent screen on load.
  static Future<void> resetRecurringTasksForChild(String childId) async {
    try {
      final taskRes = await _supabase
          .from('tasks')
          .select(
  'Task_id, Task_status, task_repet, completed_at, due_date'
)
          .eq('assigned_to_child', childId);

      final tasks = taskRes as List<dynamic>;

      for (final task in tasks) {
        if (shouldReset(task)) {
          await _supabase
              .from('tasks')
              .update({
                'Task_status': 'pending',
                'completed_at': null,
              })
              .eq('Task_id', task['Task_id']);

          debugPrint(
            'Reset task ${task['Task_id']} (${task['task_repet']}) — was completed at ${task['completed_at']}',
          );
        }
      }
    } catch (e) {
      debugPrint('TaskResetService error for child $childId: $e');
    }
  }

  /// Resets tasks for ALL children of a parent. (Use in parent screens)
  static Future<void> resetRecurringTasksForParent(String parentId) async {
    try {
      final familyRes = await _supabase
          .from('Family')
          .select('child_id')
          .eq('parent_id', parentId);

      final childIds = (familyRes as List<dynamic>)
          .map((e) => e['child_id'].toString())
          .toList();

      for (final childId in childIds) {
        await resetRecurringTasksForChild(childId);
      }
    } catch (e) {
      debugPrint('TaskResetService error for parent $parentId: $e');
    }
  }
}
