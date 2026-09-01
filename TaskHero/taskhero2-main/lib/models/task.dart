class Task {
  final int id;
  final String title;
  String status;
  final String assignedTo;
  final DateTime? createdDate;
  final DateTime? dueDate;
  final int? cashAmount;
  final int? pointAmount;
  final String? repeat;
  final DateTime? completedAt;
  final List<String> completionHistory;

  Task({
    required this.id,
    required this.title,
    required this.status,
    required this.assignedTo,
    this.createdDate,
    this.dueDate,
    this.cashAmount,
    this.pointAmount,
    this.repeat,
    this.completedAt,
    this.completionHistory = const [],
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['Task_id'],
      title: map['Task_title'] ?? "",
      status: map['Task_status'] ?? "pending",
      assignedTo: map['assigned_to_child'].toString(),
      createdDate: map['created_date'] != null
          ? DateTime.tryParse(map['created_date'].toString())
          : null,
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString())
          : null,
      cashAmount: map['Cash_amount'],
      pointAmount: map['point_amount'],
      repeat: map['task_repet'],
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'].toString())
          : null,
      completionHistory: map['completion_history'] != null
          ? List<String>.from(map['completion_history'])
          : [],
    );
  }
}
