import 'package:http/http.dart' as http;
import 'dart:convert';

class PlantIdentifier {
  static Future<String?> identify(String path) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.plantnet.org/v2/identify/all?api-key=API_KEY'),
    );

    request.files.add(await http.MultipartFile.fromPath('images', path));

    var response = await request.send();
    var res = await http.Response.fromStream(response);

    var data = jsonDecode(res.body);

    return data['results'][0]['species']['scientificName'];
  }
}