import 'package:flutter/material.dart';

import 'package:taskhero/services/conn.dart'; 
import 'package:taskhero/parent/addchild.dart';
import 'package:taskhero/parent/edit_child.dart';

class ManageChildrenPage extends StatefulWidget {
  final String parentId;

  const ManageChildrenPage({super.key, required this.parentId});

  @override
  State<ManageChildrenPage> createState() => _ManageChildrenPageState();
}

class _ManageChildrenPageState extends State<ManageChildrenPage> {
  
  Future<List<Map<String, dynamic>>> _fetchChildren() async {
    final response = await supabase
        .from('Family')
        .select('*, child(child_id, child_name, child_pic)')
        .eq('parent_id', widget.parentId);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _deleteChild(String childId) async {
    try {
      await supabase.from('tasks').delete().eq('assigned_to_child', childId);
      await supabase.from('Family').delete().eq('child_id', childId);
      await supabase.from('child').delete().eq('child_id', childId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Child and their tasks deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
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
          "Manage Children's Account",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'ADLaM Display'),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
            child: Text(
              "My Children's",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'ADLaM Display'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchChildren(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No children found."));
                }

                final childrenList = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: childrenList.length,
                  itemBuilder: (context, index) {
                    final childData = childrenList[index]['child'] as Map<String, dynamic>?;
                    if (childData == null) return const SizedBox.shrink();
                    
                    return Dismissible(
                      key: Key(childData['child_id'].toString()),
                      direction: DismissDirection.startToEnd,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 40),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirm Delete"),
                            content: const Text("Are you sure you want to delete this account and all assigned tasks?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _deleteChild(childData['child_id'].toString());
                      },
                      child: _buildChildCard(childData),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFD54F),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddChildPage(parentId: widget.parentId),
            ),
          ).then((_) => setState(() {})); 
        },
        child: const Icon(Icons.add_circle_outline, color: Colors.black, size: 35),
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (child['child_pic'] != null && child['child_pic'].isNotEmpty)
                  ? NetworkImage(child['child_pic'])
                  : null,
              child: (child['child_pic'] == null || child['child_pic'].isEmpty)
                  ? const Icon(Icons.person, size: 35, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              child['child_name'] ?? 'Unknown',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ADLaM Display'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.purple, size: 40),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditChildPage(childId: child['child_id'].toString()),
                ),
              ).then((_) => setState(() {})); 
            },
          ),
        ],
      ),
    );
  }
}