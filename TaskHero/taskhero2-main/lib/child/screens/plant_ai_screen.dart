import 'dart:typed_data'; 
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/plant_service.dart';
import 'plantchatscreen.dart'; 

class PlantAIScreen extends StatefulWidget {
  const PlantAIScreen({super.key});

  @override
  State<PlantAIScreen> createState() => _PlantAIScreenState();
}

class _PlantAIScreenState extends State<PlantAIScreen> {
  CameraController? _controller;
  final PlantService _plantService = PlantService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _showCameraView = false; 

  // الألوان والخطوط المتوافقة مع هوية التطبيق
  final Color greenBgColor = const Color(0xFFD4EDDA); 
  final Color buttonColor = const Color(0xFFF9CF45); 
  final String appFont = 'ADLaM Display';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }


  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorSnackBar("No cameras found on this device.");
        return;
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      _showErrorSnackBar("Camera error: Please check permissions.");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }


  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      final XFile photo = await _controller!.takePicture();
      final Uint8List bytes = await photo.readAsBytes();
      
      await _handleRecognition(bytes, photo.name);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar("Failed to capture image.");
    }
  }

 
  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      await _handleRecognition(bytes, image.name);
    }
  }

  
  Future<void> _handleRecognition(Uint8List bytes, String fileName) async {
    setState(() => _isProcessing = true);
    try {
      String? plantName = await _plantService.processPlantRecognitionUniversal(
        bytes,
        fileName,
        "Hero", 
      );

      setState(() {
        _isProcessing = false;
        _showCameraView = false; 
      });

      if (plantName != null) {
        _showResultDialog(plantName);
      } else {
        _showErrorSnackBar("We couldn't identify this plant. Try another angle!");
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _showCameraView = false;
      });
      _showErrorSnackBar("Connection error occurred.");
    }
  }


  void _showSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Image Source",
                style: TextStyle(fontFamily: appFont, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: buttonColor, size: 30),
                title: const Text("Take a Photo (Camera)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  if (_isCameraInitialized) {
                    setState(() => _showCameraView = true);
                  } else {
                    _showErrorSnackBar("Camera is not ready yet.");
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.photo_library, color: buttonColor, size: 30),
                title: const Text("Choose from Gallery", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: _showCameraView ? Colors.black : greenBgColor,
      body: SafeArea(
        top: !_showCameraView, // تعطيل الـ SafeArea العلوي لتغطية الكاميرا كامل الشاشة
        child: _showCameraView ? _buildCameraStreamView() : _buildWelcomePlantView(),
      ),
    );
  }

  
  Widget _buildWelcomePlantView() {
    return Stack(
      children: [
        
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language_rounded, 
                    size: 150, 
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 40),
                
                Text(
                  "Learn fun facts about me\nand how to take care of me!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: appFont,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent.shade100, 
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
                
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                  ),
                  onPressed: _showSelectionBottomSheet,
                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                  label: Text(
                    "Let's get started!",
                    style: TextStyle(fontFamily: appFont, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        Positioned(
          top: 20,
          left: 20,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.6),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraStreamView() {
    return Stack(
      children: [
        
        Positioned.fill(
          child: CameraPreview(_controller!),
        ),

        
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                    onPressed: _pickFromGallery,
                  ),

                  
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
                    onPressed: () {
                      setState(() => _showCameraView = false);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

       
        Positioned(
          top: 50,
          left: 20,
          child: CircleAvatar(
            backgroundColor: Colors.black45,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() => _showCameraView = false);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ديالوج النجاح المنبثق عند التعرف على النبتة لفتح الـ Chat مباشرة
  void _showResultDialog(String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: Color(0xFFF9CF45), 
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🌱 Mission Accomplished!", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 15),
            Text("You found a: $name", 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.pop(context); 
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantChatScreen(plantName: name),
                  ),
                );
              },
              child: const Text("Talk to your new Plant AI", 
                style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}