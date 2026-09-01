import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class PlantChatScreen extends StatefulWidget {
  final String plantName;
  const PlantChatScreen({super.key, required this.plantName});

  @override
  State<PlantChatScreen> createState() => _PlantChatScreenState();
}

class _PlantChatScreenState extends State<PlantChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  late final GenerativeModel _model;
  late final ChatSession _chat;
  

  final List<String> _suggestedQuestions = [];

  @override
  void initState() {
    super.initState();
    _initializeDynamicQuestions();
    _setupChat();
  }


  void _initializeDynamicQuestions() {
    
    final flowerKeywords = ['myosotis', 'flower', 'rose', 'tulip', 'lily', 'daisy', 'sunflower'];
    
   
    bool isFlower = flowerKeywords.any((keyword) => widget.plantName.toLowerCase().contains(keyword));
    String type = isFlower ? "flower" : "plant";

    
    _suggestedQuestions.addAll([
      "Does this $type need water and sunlight? ☀️",
      "Can insects like bees visit this $type? 🐝",
      "Where does this $type grow? 🌍",
      "Fun fact about me! ✨",
      "Can we plant this $type in our garden? 🏡",
      "How long does this $type live? ⏳",
    ]);
  }

  void _setupChat() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey:'AQ.Ab8RN6J5uyf2KaV5U9vkkKuDC7knlaL32WqL-6Pu9BaRT0C0Nw', // استبدله بمفتاحك السري الجديد الفعّال
      systemInstruction: Content.system(
          "You are a friendly, cute, and smart science-loving plant/flower called ${widget.plantName}. "
          "You are talking to a curious child. When they ask scientific or general questions about you, "
          "explain it in a super simple, fun, energetic, and magical way that a child can easily understand. "
          "Keep answers very short (2-3 sentences max), and fill them with cute emojis! Always stay in character."
      ),
    );

    _chat = _model.startChat();

    _messages.add({
      "role": "bot",
      "text": "Hi Hero! I am your friend, the ${widget.plantName}! 🧠🌱 Click on any question below to discover my secrets! ✨"
    });
  }

  Future<void> _processMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });

    try {
      final response = await _chat.sendMessage(Content.text(text));

      setState(() {
        _messages.add({
          "role": "bot",
          "text": response.text ?? "I'm a bit thirsty, can you repeat that? 💧"
        });
        _isLoading = false;
      });
    } catch (e) {
      print("Gemini Error: $e");
      setState(() {
        _messages.add({
          "role": "bot",
          "text": "Sorry, my roots are tangled. Try again later! 🪵"
        });
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🔬 Chat with ${widget.plantName}"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // شاشة عرض الرسائل والردود
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green[100] : Colors.amber[50],
                      border: Border.all(
                        color: isUser ? Colors.green[300]! : Colors.amber[200]!,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isUser ? 15 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 15),
                      ),
                    ),
                    child: Text(
                      _messages[index]["text"]!,
                      style: TextStyle(
                        fontSize: 16,
                        color: isUser ? Colors.green[900] : Colors.brown[800],
                        fontWeight: FontWeight.w500, // تم إصلاح الخطأ هنا بنجاح 🛠️
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading) const LinearProgressIndicator(color: Colors.green),

          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _suggestedQuestions.length,
                itemBuilder: (context, index) {
                  
                  final List<Color> buttonColors = [
                    Colors.amber[400]!,
                    Colors.red[300]!,
                    Colors.lightBlue[200]!,
                  ];
                  Color currentColors = buttonColors[index % buttonColors.length];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentColors, 
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isLoading 
                          ? null 
                          : () => _processMessage(_suggestedQuestions[index]),
                      child: Text(
                        _suggestedQuestions[index],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          
          Padding(
            padding: const EdgeInsets.only(bottom: 15, left: 10, right: 10, top: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "What do you want to know about me?",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.green[700],
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      _processMessage(_messageController.text);
                      _messageController.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}