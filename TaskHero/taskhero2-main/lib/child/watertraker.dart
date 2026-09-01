import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:taskhero/api/firebase_api.dart';

class WaterTrackerApp extends StatefulWidget {
  final String childId;

  const WaterTrackerApp({super.key, required this.childId});

  @override
  State<WaterTrackerApp> createState() => _WaterTrackerAppState();
}

class _WaterTrackerAppState extends State<WaterTrackerApp> {
  final supabase = Supabase.instance.client;
  
  double dailyGoal = 1500; 
  double currentWater = 0;

  Map<String, int> waterLogs = {
    "08:00 AM": 0, "10:00 AM": 0, "12:00 PM": 0,
    "02:00 PM": 0, "04:00 PM": 0, "06:00 PM": 0,
    "08:00 PM": 0, "10:00 PM": 0,
  };

  @override
  void initState() {
    super.initState();
    _initializeTracker();
  }

  Future<void> _initializeTracker() async {
    await _requestNotificationPermissions();
    await _fetchChildWeightAndCalculateGoal();
    await _fetchTodayLogs();
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? fcmToken;
        if (kIsWeb) {
          fcmToken = await messaging.getToken(
            vapidKey: "BMxmQhbJzUUIyzsjJUuh9y3bHpDK5-TbQmAlWaQu_sT2dqYBbylTevP3O3_hmbtOyavm1-aAjZaQGntqYl2KiJo"
          );
        } else {
          fcmToken = await messaging.getToken();
        }
        if (fcmToken != null) {
          await supabase.from('child').update({'fcm_token': fcmToken}).eq('child_id', widget.childId);
        }
      }
    } catch (e) {
      debugPrint("Error with notifications setup: $e");
    }
  }

  Future<void> _fetchChildWeightAndCalculateGoal() async {
    try {
      final data = await supabase
          .from('child') 
          .select('child_weight')
          .eq('child_id', widget.childId)
          .single();

      if (data != null && data['child_weight'] != null) {
        double weight = double.tryParse(data['child_weight'].toString()) ?? 30.0;
        setState(() {
          dailyGoal = weight * 50; 
        });
      }
    } catch (e) {
      debugPrint("Error fetching weight: $e");
    }
  }

  String _getClosestAvailableHour(DateTime time) {
    int hour = time.hour;
    
    if (hour < 9) return "08:00 AM";
    if (hour >= 9 && hour < 11) return "10:00 AM";
    if (hour >= 11 && hour < 13) return "12:00 PM";
    if (hour >= 13 && hour < 15) return "02:00 PM";
    if (hour >= 15 && hour < 17) return "04:00 PM";
    if (hour >= 17 && hour < 19) return "06:00 PM";
    if (hour >= 19 && hour < 21) return "08:00 PM";
    return "10:00 PM";
  }

  Future<void> _fetchTodayLogs() async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    try {
      final List<dynamic> data = await supabase
          .from('water_logs')
          .select()
          .eq('child_id', widget.childId)
          .eq('log_date', today);

      double totalIntake = 0;
      Map<String, int> updatedLogs = {
        "08:00 AM": 0, "10:00 AM": 0, "12:00 PM": 0,
        "02:00 PM": 0, "04:00 PM": 0, "06:00 PM": 0,
        "08:00 PM": 0, "10:00 PM": 0,
      };

      for (var item in data) {
        totalIntake += (item['amount_ml'] as num).toDouble();
        DateTime logTime = DateTime.parse(item['log_time']).toLocal();
        String closestHour = _getClosestAvailableHour(logTime);
        
        if (updatedLogs.containsKey(closestHour)) {
          updatedLogs[closestHour] = updatedLogs[closestHour]! + 1;
        }
      }

      setState(() {
        currentWater = totalIntake;
        waterLogs = updatedLogs;
      });
      
    } catch (e) {
      debugPrint("Error fetching today's logs: $e");
    }
  }

  void addWater() async {
    double amountToAdd = 250; 
    DateTime now = DateTime.now();
    String targetHour = _getClosestAvailableHour(now);

    setState(() {
      if (currentWater < dailyGoal) {
        currentWater += amountToAdd;
      }
      if (waterLogs.containsKey(targetHour)) {
        waterLogs[targetHour] = (waterLogs[targetHour] ?? 0) + 1;
      }
    });

    try {
      await supabase.from('water_logs').insert({
        'child_id': widget.childId, 
        'amount_ml': amountToAdd.toInt(),      
        'log_time': now.toIso8601String(), 
        'log_date': DateFormat('yyyy-MM-dd').format(now), 
      });

      await supabase.from('notifications').insert({
        'receiver_id': widget.childId,
        'sender_id': widget.childId,
        'sender_name': 'System',
        'title': 'Great Job! 💧',
        'content': 'You just drank 250 ml of water. Keep going!',
        'type': 'water_reminder',
        'is_read': false,
        'created_date': now.toIso8601String(),
      });

      try {
        await FirebaseApi().initNotification(widget.childId, 'child');
      } catch (fcmError) {
        debugPrint(fcmError.toString());
      }

    } catch (e) {
      debugPrint("Failed to record intake: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = currentWater / dailyGoal;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text("Water Tracker", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _headerCard(),
            const SizedBox(height: 30),
            _waterProgressCircle(progress),
            const SizedBox(height: 30),
            _logsSection(),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Daily goal calculated based on weight: ${dailyGoal.toInt()} ml",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _waterProgressCircle(double progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 220, height: 220,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 15,
            backgroundColor: Colors.grey[200],
            color: Colors.blueAccent,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop, size: 40, color: Colors.blue),
            const SizedBox(height: 5),
            Text("${currentWater.toInt()} ml", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text("of ${dailyGoal.toInt()} ml", style: const TextStyle(color: Colors.grey)),
          ],
        )
      ],
    );
  }

  Widget _logsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: addWater,
                icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 35),
              )
            ],
          ),
          const Divider(),
          ...waterLogs.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(e.key, style: const TextStyle(color: Colors.grey))),
                Expanded(
                  child: Wrap(
                    spacing: 5,
                    children: List.generate(e.value, (index) => const Icon(Icons.local_drink, color: Colors.blueAccent, size: 20)),
                  ),
                )
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}