import 'dart:convert';
import 'dart:typed_data'; // ضروري للتعامل مع البيانات على الويب والموبايل
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class PlantService {
  final String plantNetKey = "2b10taZXjPi5wdLixNqU0i2kie";
  final _supabase = Supabase.instance.client;

  // الدالة تعمل بشكل "Universal" (ويب وموبايل) مع الإبقاء على المدخلات لتجنب الأخطاء
  Future<String?> processPlantRecognitionUniversal(
      Uint8List imageBytes, String fileName, String childName) async {
    try {
      // 1. التعرف على النبتة عبر PlantNet
      var uri = Uri.parse(
          "https://my-api.plantnet.org/v2/identify/all?api-key=$plantNetKey");
      
      var request = http.MultipartRequest('POST', uri);

      // إضافة الصورة كبايتات لضمان عملها على المتصفح والموبايل
      request.files.add(
        http.MultipartFile.fromBytes(
          'images', 
          imageBytes,
          filename: fileName,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(data);
        
        // استخراج اسم النبتة مع التأكد من وجود بيانات
        String plantName ="Unknown plant";
        if (jsonResponse['results'] != null && jsonResponse['results'].isNotEmpty) {
          var species = jsonResponse['results'][0]['species'];
          if (species['commonNames'] != null && species['commonNames'].isNotEmpty) {
            plantName = species['commonNames'][0];
          } else {
            plantName = species['scientificNameWithoutAuthor'] ?? "Rare plant";
          }
        }

        // 2. حفظ البيانات في Supabase بدون اسم النبتة
        await _saveToSupabase(childName);

        // نُرجع اسم النبتة فقط لتعرضه في الشاشة دون حفظه بالداتا بيس
        return plantName;
      } else {
        print("Error in PlantNet API: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error during plant recognition: $e");
      return null;
    }
  }

  // دالة الحفظ تم تعديلها لحذف 'plant_name' من الـ Insert
  Future<void> _saveToSupabase(String childName) async {
    try {
      await _supabase.from('plant_logs').insert({
        'child_name': childName,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error saving data to Supabase: $e");
    }
  }
}