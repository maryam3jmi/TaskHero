import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskhero/services/conn.dart';
import 'package:taskhero/api/firebase_api.dart';

class AddTaskScreen extends StatefulWidget {
  final String parentId; 

  const AddTaskScreen({super.key, required this.parentId});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final SupabaseClient _supabase = Supabase.instance.client; 
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();

  final int staticGroupId = 1;

  List<String> selectedChildIds = [];
  int pointsCount = 10;
  String selectedRewardType = 'Points';
  DateTime? selectedDate;
  String repeatValue = 'Daily';
  bool _isLoading = false;

  late Future<List<Map<String, dynamic>>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _childrenFuture = _fetchChildren();
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFD1E9F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFBC02D), width: 2),
        ),
        title: Text(title, style: const TextStyle(color: Color(0xFFFBC02D), fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFBC02D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTasks() async {
    if (_titleController.text.trim().isEmpty || selectedChildIds.isEmpty) {
      _showMessage('Required Fields', 'Please enter a title and select at least one child.');
      return;
    }

    if (selectedDate == null) {
      _showMessage('Required Fields', 'Please choose a due date.');
      return;
    }

    bool isCashSelected = (selectedRewardType == 'Cash' || selectedRewardType == 'Both');
    if (isCashSelected && (double.tryParse(_cashController.text) ?? 0) <= 0) {
      _showMessage('Required Fields', 'Please enter a valid cash amount.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> tasksToInsert = selectedChildIds.map((childId) {
        return {
          'Task_title': _titleController.text.trim(),
          'assigned_to_child': childId,
          'created_by_parent': widget.parentId, 
          'group_id': staticGroupId,
          'Task_status': 'pending',
          'Cash_amount': (selectedRewardType != 'Cash') ? 0 : (int.tryParse(_cashController.text) ?? 0),
          'point_amount': (selectedRewardType != 'Points') ? 0 : pointsCount,
          'created_date': DateTime.now().toIso8601String(),
          'due_date': selectedDate!.toIso8601String(),
          'task_repet': repeatValue,
        };
      }).toList();

      await _supabase.schema('public').from('tasks').insert(tasksToInsert);
      
      final List<Map<String, dynamic>> notificationsToInsert = selectedChildIds.map((childId) {
        return {
          'receiver_id': childId,                      
          'sender_id': widget.parentId,                
          'sender_name': 'Parent',                     
          'title': 'New Task Assigned! 🚀',               
          'content': 'You have a new task: ${_titleController.text.trim()}', 
          'type': 'task',                               
          'is_read': false,                            
          'created_date': DateTime.now().toIso8601String(),
        };
      }).toList();

      await _supabase.schema('public').from('notifications').insert(notificationsToInsert);

      for (String childId in selectedChildIds) {
        try {
          await FirebaseApi().initNotification(childId, 'child');
        } catch (fcmError) {
          debugPrint(fcmError.toString());
        }
      }

      if (!mounted) return;
      _showMessage('Success', 'Tasks and Notifications assigned successfully!');

      setState(() {
        _titleController.clear();
        _cashController.clear();
        selectedChildIds.clear();
        selectedDate = null;
        pointsCount = 10;
        selectedRewardType = 'Points';
      });
    } catch (e) {
      _showMessage('Error', 'Failed to save tasks: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchChildren() async {
    final response = await _supabase
        .schema('public')
        .from('Family')
        .select('family_id, child:child_id(child_id, child_name, child_pic)')
        .eq('parent_id', widget.parentId); 
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isCashEnabled = selectedRewardType == 'Cash' || selectedRewardType == 'Both';
    bool isPointsEnabled = selectedRewardType == 'Points' || selectedRewardType == 'Both';

    return Scaffold(
      backgroundColor: const Color(0xFFA6CBE3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), 
          onPressed: () => Navigator.pop(context)
        ),
        title: const Text('Add New Task', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LabelText(text: 'Task Title'),
            CustomTextField(hint: 'e.g. walk the dog', controller: _titleController),
            const SizedBox(height: 20),
            const LabelText(text: 'Assign to'),
            _buildAssignToSection(),
            const SizedBox(height: 20),
            const LabelText(text: 'Reward Type'),
            _buildRewardTypeSection(),
            const SizedBox(height: 20),
            _buildAmountAndPointsSection(isCashEnabled, isPointsEnabled),
            const SizedBox(height: 20),
            _buildDateAndRepeatSection(),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendTasks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Send', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignToSection() {
    return SizedBox(
      height: 110, 
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _childrenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text("No children found.");
          }

          final familyList = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: familyList.length,
            itemBuilder: (context, index) {
              final childData = familyList[index]['child'] as Map<String, dynamic>?;
              
              final String actualChildId = childData?['child_id']?.toString() ?? '';
              final bool isSelected = selectedChildIds.contains(actualChildId);

              return GestureDetector(
                onTap: () {
                  if (actualChildId.isEmpty) return;
                  setState(() {
                    if (isSelected) {
                      selectedChildIds.remove(actualChildId);
                    } else {
                      selectedChildIds.add(actualChildId);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: UserAvatar(
                    name: childData?['child_name'] ?? 'Unknown',
                    imageUrl: childData?['child_pic'],
                    isSelected: isSelected,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRewardTypeSection() {
    return Row(
      children: ['Points', 'Cash', 'Both'].map((label) {
        bool isSelected = selectedRewardType == label;
        return GestureDetector(
          onTap: () => setState(() {
            selectedRewardType = label;
            if (label == 'Points') _cashController.clear();
            if (label == 'Cash') pointsCount = 0;
          }),
          child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Row(children: [
              Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 22, color: isSelected ? Colors.black : Colors.black54),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountAndPointsSection(bool isCashEnabled, bool isPointsEnabled) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LabelText(text: 'Cash Amounts'),
              CustomTextField(hint: '0.0', controller: _cashController, enabled: isCashEnabled, isNumber: true),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LabelText(text: 'Points'),
            PointsCounter(
              value: pointsCount,
              onChanged: isPointsEnabled ? (val) => setState(() => pointsCount = val) : null,
              enabled: isPointsEnabled,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateAndRepeatSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LabelText(text: 'Due Date'),
              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: Container(
                  height: 55,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.yellow.shade700, width: 2),
                  ),
                  child: Text(
                    selectedDate == null ? "Select date" : selectedDate.toString().split(' ')[0],
                    style: TextStyle(color: selectedDate == null ? Colors.grey : Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LabelText(text: 'Repeat'),
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.yellow.shade700, width: 2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: repeatValue,
                    isExpanded: true,
                    items: ['Daily', 'Weekly', 'Monthly'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => repeatValue = val!),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final bool isNumber;

  const CustomTextField({super.key, required this.hint, required this.controller, this.enabled = true, this.isNumber = false});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: enabled ? Colors.yellow.shade700 : Colors.grey, width: 2),
        ),
        child: TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            border: InputBorder.none,
          ),
        ),
      );
}

class PointsCounter extends StatelessWidget {
  final int value;
  final Function(int)? onChanged;
  final bool enabled;

  const PointsCounter({super.key, required this.value, this.onChanged, this.enabled = true});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: enabled ? Colors.yellow.shade700 : Colors.grey, width: 2),
        ),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: enabled ? () => onChanged?.call(value > 0 ? value - 1 : 0) : null),
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: enabled ? Colors.black : Colors.grey)),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: enabled ? () => onChanged?.call(value + 1) : null),
        ]),
      );
}

class LabelText extends StatelessWidget {
  final String text;
  const LabelText({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
}

class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isSelected;

  const UserAvatar({super.key, required this.name, this.imageUrl, this.isSelected = false});

  @override
  Widget build(BuildContext context) => Column(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: isSelected ? const Color(0xFFFBC02D) : Colors.transparent,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty) ? NetworkImage(imageUrl!) : null,
            child: (imageUrl == null || imageUrl!.isEmpty) ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ]);
}