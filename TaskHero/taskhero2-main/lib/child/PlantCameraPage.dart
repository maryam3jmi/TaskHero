// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'plant_identifier.dart';
// import 'package:camera/camera.dart';

// class PlantCameraPage extends StatefulWidget {
//   @override
//   State<PlantCameraPage> createState() => _PlantCameraPageState();
// }

// class _PlantCameraPageState extends State<PlantCameraPage> {
//   CameraController? controller;
//   List<CameraDescription>? cameras;
//   XFile? image;

//   @override
//   void initState() {
//     super.initState();
//     initCamera();
//   }

//   Future<void> initCamera() async {
//     cameras = await availableCameras();
//     controller = CameraController(
//       cameras![0],
//       ResolutionPreset.high,
//     );
//     await controller!.initialize();
//     if (!mounted) return;
//     setState(() {});
//   }

//   Future<void> takePicture() async {
//     if (controller == null || !controller!.value.isInitialized) return;

//     image = await controller!.takePicture();
//     setState(() {});

//     print("Image path: ${image!.path}");
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (controller == null || !controller!.value.isInitialized) {
//       return Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       body: Stack(
//         children: [
//           CameraPreview(controller!),
//           Positioned(
//             top: 60,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Text(
//                 "Scan Plant 🌱",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           Center(
//             child: Container(
//               width: 250,
//               height: 250,
//               child: Stack(
//                 children: [
//                   buildCorner(top: 0, left: 0),
//                   buildCorner(top: 0, right: 0),
//                   buildCorner(bottom: 0, left: 0),
//                   buildCorner(bottom: 0, right: 0),
//                 ],
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 40,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: GestureDetector(
//                 onTap: takePicture,
//                 child: Container(
//                   width: 70,
//                   height: 70,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 4),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           if (image != null)
//             Positioned(
//               bottom: 40,
//               left: 20,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.file(
//                   File(image!.path),
//                   width: 60,
//                   height: 60,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget buildCorner({
//     double? top,
//     double? bottom,
//     double? left,
//     double? right,
//   }) {
//     return Positioned(
//       top: top,
//       bottom: bottom,
//       left: left,
//       right: right,
//       child: Container(
//         width: 30,
//         height: 30,
//         decoration: BoxDecoration(
//           border: Border(
//             top: top != null
//                 ? BorderSide(color: Colors.black, width: 3)
//                 : BorderSide.none,
//             left: left != null
//                 ? BorderSide(color: Colors.black, width: 3)
//                 : BorderSide.none,
//             right: right != null
//                 ? BorderSide(color: Colors.black, width: 3)
//                 : BorderSide.none,
//             bottom: bottom != null
//                 ? BorderSide(color: Colors.black, width: 3)
//                 : BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }
// }
