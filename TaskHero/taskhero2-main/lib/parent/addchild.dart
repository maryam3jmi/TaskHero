import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taskhero/services/conn.dart'; 
import 'package:bcrypt/bcrypt.dart'; 

class AddChildPage extends StatefulWidget {
  final String parentId; 

  const AddChildPage({super.key, required this.parentId});

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController(); 
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  void _showAlert(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333).withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontFamily: 'ADLaM Display')),
        content: Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'ADLaM Display')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) Navigator.pop(context);
            },
            child: const Text("OK", style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _addChild() async {
    String username = _userController.text.trim();
    String password = _passController.text; 
    
    final currentUser = supabase.auth.currentUser;
    
    if (currentUser == null) {
      _showAlert("Error", "You must be logged in to add a child.");
      return;
    }

    if (_nameController.text.isEmpty || username.isEmpty || password.isEmpty) {
      _showAlert("Required", "Please fill Name, Username, and Password.");
      return;
    }

    if (username.length < 8) {
      _showAlert("Error", "Username must be at least 8 characters long.");
      return;
    }

    RegExp passwordRegExp = RegExp(r'^(?=.*[A-Z]).{8,}$');
    if (!passwordRegExp.hasMatch(password)) {
      _showAlert("Error", "Password must be at least 8 characters long and contain at least one uppercase letter.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final duplicate = await supabase
          .from('child')
          .select()
          .eq('child_username', username)
          .maybeSingle();

      if (duplicate != null) {
        _showAlert("Error", "Username already taken.");
        setState(() => _isLoading = false);
        return;
      }

      String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      String? imageUrl;
      if (_imageBytes != null) {
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
        await supabase.storage.from('avatars').uploadBinary(fileName, _imageBytes!);
        imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final response = await supabase.from('child').insert({
        'child_name': _nameController.text,
        'child_username': username,
        'child_password': hashedPassword, 
        'child_gender': _selectedGender,
        'birth_date': _selectedDate?.toIso8601String(),
        'child_weight': _weightController.text,
        'child_height': _heightController.text,
        'child_pic': imageUrl,
      }).select('child_id').single();

      final newChildId = response['child_id'];
      await supabase.from('Family').insert({
        'parent_id': widget.parentId,
        'child_id': newChildId,
      });

      _showAlert("Success", "Child added successfully! ✅", isSuccess: true);
    } catch (e) {
      _showAlert("Error", e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA9CDE3),
      appBar: AppBar(
        title: const Text("Add New Hero", 
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ADLaM Display')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final XFile? img = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (img != null) {
                          final bytes = await img.readAsBytes();
                          setState(() => _imageBytes = bytes);
                        }
                      },
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                        child: _imageBytes == null 
                          ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey) 
                          : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(_nameController, "Child Name"),
                  _field(_userController, "Username"),
                  _field(_passController, "Password", isPass: true),
                  Row(children: [
                    Expanded(child: _dropdownGender()),
                    const SizedBox(width: 10),
                    Expanded(child: _datePicker()),
                  ]),
                  Row(children: [
                    Expanded(child: _field(_weightController, "Weight", isNum: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_heightController, "Height", isNum: true)),
                  ]),
                  const SizedBox(height: 30),
                  Row(children: [
                    Expanded(child: _btn("Add Child", _addChild)),
                    const SizedBox(width: 10),
                    Expanded(child: _btn("Cancel", () => Navigator.pop(context), color: Colors.white70)),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {bool isPass = false, bool isNum = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextField(
          controller: ctrl,
          obscureText: isPass,
          keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
          decoration: InputDecoration(
              labelText: hint,
              filled: true,
              fillColor: Colors.white70,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
          ),
        ),
      );

  Widget _dropdownGender() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(15)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedGender,
            isExpanded: true,
            hint: const Text("Gender"),
            items: ["Boy", "Girl"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedGender = v),
          ),
        ),
      );

  Widget _datePicker() => GestureDetector(
        onTap: () async {
          DateTime? p = await showDatePicker(
              context: context, 
              initialDate: DateTime.now(), 
              firstDate: DateTime(2000), 
              lastDate: DateTime.now());
          if (p != null) setState(() => _selectedDate = p);
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(15)),
          child: Text(_selectedDate == null ? "Birth Date" : _selectedDate!.toIso8601String().split('T')[0]),
        ),
      );

  Widget _btn(String txt, VoidCallback fn, {Color color = const Color(0xFFF9CF45)}) => ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.symmetric(vertical: 15)),
        onPressed: fn,
        child: Text(txt, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ); 
}