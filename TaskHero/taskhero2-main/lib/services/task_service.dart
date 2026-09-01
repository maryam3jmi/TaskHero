import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TaskService {
  final supabase = Supabase.instance.client;

  Future<List<Task>> getTasks(String childId) async {
    final res = await supabase
        .from('tasks')
        .select()
        .eq('assigned_to_child', childId)
        .order('created_date');

    return (res as List).map((e) => Task.fromMap(e)).toList();
  }

  Future<void> updateTaskStatus(int taskId, String status) async {
    await supabase
        .from('tasks')
        .update({'Task_status': status})
        .eq('Task_id', taskId);
  }
}