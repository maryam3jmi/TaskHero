import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animate_do/animate_do.dart';

class TaskHeroHelpPage extends StatefulWidget {
  const TaskHeroHelpPage({super.key}); // أضف const هنا و {super.key}

  @override
  State<TaskHeroHelpPage> createState() => _TaskHeroHelpPageState();
}


class _TaskHeroHelpPageState extends State<TaskHeroHelpPage> {
  late FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _configureTts();
  }

  void _configureTts() async {
    await _tts.setLanguage("en-US");
    // إعدادات لصوت أكثر طبيعية ووضوحاً
    await _tts.setPitch(1.0); // القيمة 1.0 هي الصوت الطبيعي الافتراضي
    await _tts.setSpeechRate(0.4); // سرعة هادئة ومناسبة للفهم
    await _tts.setVolume(1.0);
  }

  void _speak(String text) async {
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFC5E3F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Help & Support",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'ADLaM Display'),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // عرض أيقونة التطبيق بشكل بارز في الأعلى بدلاً من البحث
              ZoomIn(
                child: Center(
                  child: Image.asset(
                    'assets/icon.png',
                    height: 140,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.help_outline, size: 100, color: Colors.blueAccent),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Tap any card to hear the instruction!",
                style: TextStyle(color: Colors.blueGrey, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 25),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.9,
                children: [
                  _buildHelpCard(context, "1. Daily Mission", "This is where you find all your jobs for the day", Icons.assignment, Colors.orange),
                  _buildHelpCard(context, "2. Finish Mission", "Tap the circle next to mission when you have finished it", Icons.check_circle, Colors.yellow.shade700),
                  _buildHelpCard(context, "3. Earn Points", "Finishing mission earns you points that you can use later", Icons.star, Colors.amber),
                  _buildHelpCard(context, "4. Get Rewards", "Trade your points for cool rewards your parents set up", Icons.emoji_events, Colors.redAccent),
                  _buildHelpCard(context, "5. Water Tracker", "Drink water and tap the glass to keep your hero hydrated", Icons.local_drink, Colors.blue),
                  _buildHelpCard(context, "6. Study Timer", "Use the timer to focus on your lessons and win extra time", Icons.timer, Colors.deepPurple),
                  _buildHelpCard(context, "7. My Plant", "Talk to your AI plant assistant to learn how to grow it", Icons.local_florist, Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context, String title, String desc, IconData icon, Color iconColor) {
    return FadeInUp(
      child: GestureDetector(
        onTap: () {
          _speak("$title. $desc");
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            builder: (context) => Container(
              padding: EdgeInsets.all(25),
              height: 250,
              child: Column(
                children: [
                  Icon(icon, size: 50, color: iconColor),
                  SizedBox(height: 15),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 10),
                  Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () { _tts.stop(); Navigator.pop(context); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, 
                      shape: StadiumBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12)
                    ),
                    child: Text("Close", style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                ],
              ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 35, color: iconColor),
              SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 4),
              Text(
                desc, 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 10, color: Colors.grey[600]), 
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}