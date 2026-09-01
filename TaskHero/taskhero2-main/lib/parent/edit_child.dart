import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskhero/services/conn.dart';
import 'package:intl/intl.dart';
import 'package:bcrypt/bcrypt.dart';

class EditChildPage extends StatefulWidget {
  final String childId;
  const EditChildPage({super.key, required this.childId});

  @override
  State<EditChildPage> createState() => _EditChildPageState();
}

class _EditChildPageState extends State<EditChildPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChildData();
  }

  Future<void> _fetchChildData() async {
    try {
      final data = await supabase
          .from('child')
          .select()
          .eq('child_id', widget.childId)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _nameController.text = data['child_name']?.toString() ?? '';
          _userController.text = data['child_username']?.toString() ?? '';
          _passController.text = data['child_password']?.toString() ?? '';
          _weightController.text = data['child_weight']?.toString() ?? '';
          _heightController.text = data['child_height']?.toString() ?? '';
          _selectedGender = data['child_gender'];
          _existingImageUrl = data['child_pic'];
          if (data['birth_date'] != null) {
            _selectedDate = DateTime.parse(data['birth_date']);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      _showAlert("Error", "Failed to load data");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333).withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            fontFamily: 'ADLaM Display',
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'ADLaM Display',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateChild() async {
    final String username = _userController.text;
    final String password = _passController.text;

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
      String? imageUrl = _existingImageUrl;
      if (_imageBytes != null) {
        final fileName = 'child_${widget.childId}_${DateTime.now().millisecondsSinceEpoch}.png';
        await supabase.storage.from('avatars').uploadBinary(
              fileName,
              _imageBytes!,
              fileOptions: const FileOptions(
                contentType: 'image/png',
                upsert: true,
              ),
            );
        imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      await supabase.from('child').update({
        'child_name': _nameController.text,
        'child_username': username,
        'child_password': hashedPassword,
        'child_gender': _selectedGender,
        'birth_date': _selectedDate?.toIso8601String(),
        'child_weight': _weightController.text,
        'child_height': _heightController.text,
        'child_pic': imageUrl,
      }).eq('child_id', widget.childId);

      _showAlert("Success", "Profile updated successfully! ✅");
    } catch (e) {
      _showAlert("Error", e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC9D9E6),
      appBar: AppBar(
        title: const Text("Edit Hero Profile",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'ADLaM Display')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await ImagePicker()
                          .pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() => _imageBytes = bytes);
                      }
                    },
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : (_existingImageUrl != null
                              ? NetworkImage(_existingImageUrl!)
                              : null) as ImageProvider?,
                      child: (_imageBytes == null && _existingImageUrl == null)
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _inputField(_nameController, "Name"),
                  _inputField(_userController, "Username"),
                  _inputField(_passController, "Password", isPass: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                          labelText: "Gender",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15))),
                      items: ["Girl", "Boy"]
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                    ),
                  ),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: IgnorePointer(
                      child: _inputField(
                        TextEditingController(
                            text: _selectedDate == null
                                ? ""
                                : DateFormat('yyyy-MM-dd')
                                    .format(_selectedDate!)),
                        "Birth Date",
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: _inputField(_weightController, "Weight (kg)",
                              isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _inputField(_heightController, "Height (cm)",
                              isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _actionButton("Update Now", _updateChild)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _actionButton(
                              "Cancel", () => Navigator.pop(context))),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _inputField(TextEditingController controller, String label,
      {bool isPass = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
        decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15))),
      ),
    );
  }

  Widget _actionButton(String title, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF9CF45),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(vertical: 15)),
      onPressed: onTap,
      child: Text(title,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }
}