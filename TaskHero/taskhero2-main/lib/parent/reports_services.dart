import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final _supabase = Supabase.instance.client;

  /// Get children linked to current parent
  Future<List<Map<String, dynamic>>> getChildren() async {
    final parentId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('Family')
        .select('''
          child_id,
          child:child_id (
            child_name
          )
        ''')
        .eq('parent_id', parentId);

    return (response as List).map((item) {
      return {
        'child_id': item['child_id'],
        'child_name': item['child']?['child_name'] ?? 'Unknown',
      };
    }).toList();
  }

  /// Generate child report
  Future<Map<String, dynamic>> getChildReport(
    String childId,
    String period,
  ) async {
    final now = DateTime.now();

    final days = period == 'week' ? 7 : 30;

    final currentPeriodStart = now.subtract(Duration(days: days));

    final previousPeriodStart = now.subtract(Duration(days: days * 2));

    /// ---------------------------------------------------
    /// CHILD DATA
    /// ---------------------------------------------------

    final childResponse = await _supabase
        .from('child')
        .select('child_point')
        .eq('child_id', childId)
        .single();

    final totalPoints = (childResponse['child_point'] as num?)?.toInt() ?? 0;

    /// ---------------------------------------------------
    /// CURRENT TASKS
    /// ---------------------------------------------------

    final tasksResponse = await _supabase
        .from('tasks')
        .select('''
          Task_id,
          Task_title,
          Task_status,
          point_amount,
          Cash_amount,
          task_repet,
          created_date,
          completed_at
        ''')
        .eq('assigned_to_child', childId)
        .gte('created_date', currentPeriodStart.toIso8601String());

    final List tasks = tasksResponse as List;

    /// Count completed tasks within selected period
    final completedTasks = tasks.where((task) {
      if (task['completed_at'] == null) return false;

      final completedDate = DateTime.parse(task['completed_at']);

      return completedDate.isAfter(currentPeriodStart);
    }).toList();

    final completed = completedTasks.length;
    final total = tasks.length;

    /// ---------------------------------------------------
    /// PREVIOUS PERIOD TASKS
    /// ---------------------------------------------------

    final previousTasksResponse = await _supabase
        .from('tasks')
        .select('''
          Task_status,
          completed_at
        ''')
        .eq('assigned_to_child', childId)
        .gte('created_date', previousPeriodStart.toIso8601String())
        .lt('created_date', currentPeriodStart.toIso8601String());

    final List previousTasks = previousTasksResponse as List;

    final prevCompleted = previousTasks.where((task) {
      if (task['completed_at'] == null) return false;

      final completedDate = DateTime.parse(task['completed_at']);

      return completedDate.isAfter(previousPeriodStart) &&
          completedDate.isBefore(currentPeriodStart);
    }).length;

    final prevTotal = previousTasks.length;

    final currentRate = total > 0 ? (completed / total) * 100 : 0.0;

    final previousRate = prevTotal > 0
        ? (prevCompleted / prevTotal) * 100
        : 0.0;

    final trend = currentRate - previousRate;

    /// ---------------------------------------------------
    /// WATER LOGS
    /// ---------------------------------------------------

    final waterResponse = await _supabase
        .from('water_logs')
        .select('''
          amount_ml,
          log_time
        ''')
        .eq('child_id', childId)
        .gte('log_time', currentPeriodStart.toIso8601String())
        .order('log_time', ascending: false);

    final List waterLogs = waterResponse as List;

    final totalWater = waterLogs.fold<int>(
      0,
      (sum, item) => sum + ((item['amount_ml'] ?? 0) as int),
    );

    /// ---------------------------------------------------
    /// ACTIVITY FEED
    /// ---------------------------------------------------

    List<Map<String, dynamic>> activities = [];

    for (var task in tasks) {
      activities.add({
        'title': task['Task_title'] ?? 'Task',
        'subtitle': 'Status: ${task['Task_status'] ?? 'pending'}',
        'icon': 'task',
        'date': DateTime.parse(task['created_date']),
      });
    }

    for (var water in waterLogs) {
      activities.add({
        'title': 'Drank ${water['amount_ml']} ml of water',
        'subtitle': 'Hydration Log',
        'icon': 'water',
        'date': DateTime.parse(water['log_time']),
      });
    }

    activities.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    final recentActivities = activities.take(5).toList();

    /// ---------------------------------------------------
    /// WATER CHART
    /// ---------------------------------------------------

    List<Map<String, dynamic>> waterChart = [];

    if (period == 'week') {
      final daysMap = {
        'Sun': 0.0,
        'Mon': 0.0,
        'Tue': 0.0,
        'Wed': 0.0,
        'Thu': 0.0,
        'Fri': 0.0,
        'Sat': 0.0,
      };

      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (var water in waterLogs) {
        final date = DateTime.parse(water['log_time']);

        final day = weekdays[date.weekday - 1];

        daysMap[day] = (daysMap[day] ?? 0) + ((water['amount_ml'] ?? 0) as num);
      }

      daysMap.forEach((day, value) {
        waterChart.add({'day': day, 'value': value});
      });
    } else {
      final buckets = {'1-7': 0.0, '8-14': 0.0, '15-21': 0.0, '22+': 0.0};

      for (var water in waterLogs) {
        final date = DateTime.parse(water['log_time']);

        final amount = (water['amount_ml'] ?? 0).toDouble();

        if (date.day <= 7) {
          buckets['1-7'] = buckets['1-7']! + amount;
        } else if (date.day <= 14) {
          buckets['8-14'] = buckets['8-14']! + amount;
        } else if (date.day <= 21) {
          buckets['15-21'] = buckets['15-21']! + amount;
        } else {
          buckets['22+'] = buckets['22+']! + amount;
        }
      }

      buckets.forEach((day, value) {
        waterChart.add({'day': day, 'value': value});
      });
    }

    /// ---------------------------------------------------
    /// RETURN REPORT
    /// ---------------------------------------------------

    return {
      'tasks': {
        'completed': completed,
        'total': total,
        'rate': currentRate,
        'trend': trend,
      },

      'totalPoints': totalPoints,

      'totalWater': totalWater,

      'activity': recentActivities,

      'focus': [
        {'type': 'Tasks Completed', 'value': completed.toDouble()},
        {'type': 'Water Logs', 'value': waterLogs.length.toDouble()},
      ],

      'waterChart': waterChart,
    };
  }
}
