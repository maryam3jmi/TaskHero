import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:taskhero/child/child_main.dart'; 
import 'package:taskhero/services/session.dart';

class StudyTimerPage extends StatefulWidget {
  const StudyTimerPage({super.key});

  @override
  _StudyTimerPageState createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends State<StudyTimerPage> {
  final Color bgColor = const Color(0xFFA9CDE3);
  final Color iconColor = const Color(0xFFF9CF45);
  final String appFont = 'ADLaM Display';

  int _seconds = 1500; 
  int _selectedStudyMin = 25; 
  int _selectedBreakMin = 5;   
  Timer? _timer;
  bool _isRunning = false;
  bool _isStudyMode = true; 

  bool _showAccomplishPage = false;
  int _accomplishedMins = 0;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void _updateDuration(int mins, bool isStudy) {
    if (_isRunning) return; 
    setState(() {
      _isStudyMode = isStudy;
      if (isStudy) {
        _selectedStudyMin = mins;
        _seconds = mins * 60;
      } else {
        _selectedBreakMin = mins;
        _seconds = mins * 60;
      }
    });
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });
      } else {
        _timer?.cancel();
        
        final mins = _isStudyMode ? _selectedStudyMin : _selectedBreakMin;

        setState(() {
          _isRunning = false;
          _accomplishedMins = mins;
        });

        _showEndNotification();

        if (_isStudyMode) {
          setState(() {
            _showAccomplishPage = true; 
          });
        } else {
          _showBreakEndDialog();
        }
      }
    });
  }

  void _showBreakEndDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Break Time Over!",
            style: TextStyle(fontFamily: appFont, color: Colors.black, fontSize: 22),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            "Your break has ended. Ready to focus again?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(context).pop(); 
                setState(() {
                  _isStudyMode = true; 
                  _resetTimer();
                });
              },
              child: Text("OK", style: TextStyle(fontFamily: appFont, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _seconds = (_isStudyMode ? _selectedStudyMin : _selectedBreakMin) * 60;
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showEndNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'timer_channel_id', 'Timer Notifications',
      importance: Importance.max, priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0,
      "Time's up!", _isStudyMode ? 'You Did it!' : 'Break is over, let\'s get back to work!', platformDetails,
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _showAccomplishPage ? _buildAccomplishScreen() : _buildMainTimerScreen(),
        ),
      ),
    );
  }

  Widget _buildMainTimerScreen() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 10),
        _buildMainCard(),
        const SizedBox(height: 15),
        _buildTimeSettings(),
        const SizedBox(height: 15),
        _buildStatsRow(),
        const Spacer(),
      ],
    );
  }

  Widget _buildAccomplishScreen() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 80, color: iconColor),
            const SizedBox(height: 20),
            Text(
              "YOU ACCOMPLISH!",
              style: TextStyle(fontFamily: appFont, fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 15),
            Text(
              "Time Spent: $_accomplishedMins Minutes",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(height: 35),
            Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    setState(() {
                      _showAccomplishPage = false;
                      _resetTimer();
                    });
                  },
                  child: Text("Continue Studying", style: TextStyle(fontFamily: appFont, fontSize: 16)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    setState(() {
                      _showAccomplishPage = false;
                      _selectedStudyMin = 25;
                      _isStudyMode = true;
                      _seconds = 25 * 60;
                      _isRunning = false;
                    });

                    if (AppSession.childId != null) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => ChildHomePage(childId: AppSession.childId!)),
                        (route) => false,
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Finish", style: TextStyle(fontFamily: appFont, fontSize: 16)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              _timer?.cancel(); 
              if (AppSession.childId != null) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => ChildHomePage(childId: AppSession.childId!)),
                  (route) => false,
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: _circleIcon(Icons.arrow_back_ios_new),
          ),
          Text("Study Time", style: TextStyle(fontFamily: appFont, fontSize: 22, fontWeight: FontWeight.bold)),
          _circleIcon(Icons.sentiment_satisfied_alt),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: Colors.black),
    );
  }

  Widget _buildMainCard() {
    int maxSeconds = (_isStudyMode ? _selectedStudyMin : _selectedBreakMin) * 60;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(40)),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180, height: 180,
                child: CircularProgressIndicator(
                  value: maxSeconds > 0 ? _seconds / maxSeconds : 0,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ),
              Column(
                children: [
                  Text(_formatTime(_seconds), style: TextStyle(fontFamily: appFont, fontSize: 40, fontWeight: FontWeight.bold)),
                  Text(_isStudyMode ? "Focus Time" : "Break Time", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.refresh, size: 28), onPressed: _resetTimer),
              GestureDetector(
                onTap: _isRunning ? _stopTimer : _startTimer,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                  child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 35, color: Colors.black),
                ),
              ),
              IconButton(icon: const Icon(Icons.stop, size: 28, color: Colors.redAccent), onPressed: _stopTimer),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimeSettings() {
    return Column(
      children: [
        _settingContainer("STUDY DURATION", [2, 25, 45], true),
        const SizedBox(height: 10),
        _settingContainer("BREAK TIME", [5, 10, 15], false),
      ],
    );
  }

  Widget _settingContainer(String title, List<int> options, bool isStudy) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: options.map((opt) {
              bool isSelected = isStudy ? (_selectedStudyMin == opt && _isStudyMode) : (_selectedBreakMin == opt && !_isStudyMode);
              return GestureDetector(
                onTap: () => _updateDuration(opt, isStudy),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? (isStudy ? iconColor : bgColor) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                  ),
                  child: Text("${opt}m", style: TextStyle(fontFamily: appFont, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    int currentMins = _isStudyMode ? _selectedStudyMin : _selectedBreakMin;

    return Row(
      children: [
        Expanded(child: _infoBox("MODE ACTIVE", _isStudyMode ? "Focus Mode" : "Break Mode")),
        const SizedBox(width: 10),
        Expanded(child: _infoBox("SELECTED TIME", "$currentMins min")),
      ],
    );
  }

  Widget _infoBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: TextStyle(fontFamily: appFont, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}