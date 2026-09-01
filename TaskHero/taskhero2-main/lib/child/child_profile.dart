import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChildProfilePage extends StatefulWidget {
  final String childId;

  const ChildProfilePage({
    super.key,
    required this.childId,
  });

  @override
  State<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends State<ChildProfilePage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;

  String childName = '';
  String? childImage;
  String birthdayString = '';
  int childAge = 0;

  int tasksCompleted = 0;
  int pointsEarned = 0;
  int rewardsEarned = 0;

  final int targetPoints = 200;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    try {
      // 1. Fetch child data
      final childResponse = await supabase
          .from('child')
          .select()
          .eq('child_id', widget.childId)
          .single();

      // Calculate age and format birthday
      if (childResponse['birth_date'] != null) {
        DateTime birthDate = DateTime.parse(childResponse['birth_date']);
        int age = DateTime.now().year - birthDate.year;
        if (DateTime.now().month < birthDate.month ||
            (DateTime.now().month == birthDate.month &&
                DateTime.now().day < birthDate.day)) {
          age--;
        }
        childAge = age;
        birthdayString = DateFormat('MMM dd').format(birthDate);
      }

      // 2. Fetch completed tasks and sum points
      final tasksResponse = await supabase
          .from('tasks')
          .select('point_amount')
          .eq('assigned_to_child', widget.childId)
          .eq('Task_status', 'completed');

      int completedCount = tasksResponse.length;
      int totalPoints = 0;
      for (var task in tasksResponse) {
        totalPoints += (task['point_amount'] as num? ?? 0).toInt();
      }

      setState(() {
        childName = childResponse['child_name']?.toString() ?? 'Hero';
        childImage = childResponse['child_pic']?.toString();
        tasksCompleted = completedCount;
        pointsEarned = totalPoints;
        
        
        rewardsEarned = totalPoints ~/ targetPoints; 
        
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // تعديل إضافي بسيط: شريط التقدم سيعيد الحساب من 0 بعد كل 200 نقطة حتى لا يمتلئ بشكل دائم
    int pointsInCurrentLevel = pointsEarned % targetPoints;
    double progressPercent = (pointsInCurrentLevel / targetPoints).clamp(0.0, 1.0);

    const Color backgroundBlue = Color(0xFFB0D4EC);

    return Scaffold(
      backgroundColor: backgroundBlue,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back arrow
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 28, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    Text(
                      "$childName's Profile",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Profile avatar with yellow border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFFDEB94), width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: childImage != null &&
                                childImage!.isNotEmpty
                            ? NetworkImage(childImage!)
                            : const AssetImage('assets/frog_avatar.png')
                                as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Child name
                    Text(
                      childName,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3E50),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Age and birthday cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard("Age", childAge.toString()),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                              "Birthday",
                              birthdayString.isNotEmpty ? birthdayString : '—'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Points progress header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Next reward: Trophy!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D3E50),
                          ),
                        ),
                        Text(
                          "$pointsInCurrentLevel / $targetPoints points",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D3E50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Progress bar
                    Container(
                      height: 20,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                width: constraints.maxWidth * progressPercent,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7DE6A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.emoji_events_rounded,
                            iconColor: const Color(0xFFE75C43),
                            value: rewardsEarned.toString(),
                            label: "Rewards earned",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star_rounded,
                            iconColor: const Color(0xFFF7CD46),
                            value: pointsEarned.toString(),
                            label: "Points earned",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle_rounded,
                            iconColor: const Color(0xFFE3564A),
                            value: tasksCompleted.toString(),
                            label: "Tasks completed",
                            isCheckIcon: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool isCheckIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFCCE3F3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: isCheckIcon
                ? Icon(Icons.check_circle_outline_rounded,
                    size: 34, color: iconColor)
                : Icon(icon, size: 34, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D3E50),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334257),
            ),
          ),
        ],
      ),
    );
  }
}