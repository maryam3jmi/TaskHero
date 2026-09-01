import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskhero/child/screens/plant_ai_screen.dart';
import 'package:taskhero/child/study_timer.dart';
import 'childActivityPage.dart';
import 'task_view.dart';
import 'package:taskhero/chat_page.dart';
import 'package:taskhero/services/session.dart';
import 'child_info.dart';
import 'helpchild.dart';
import 'watertraker.dart';
import 'package:taskhero/services/chat/chatting_servise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'child_profile.dart';
import 'package:taskhero/splash_screen.dart'; // Added splash screen import

class ChildHomePage extends StatefulWidget {
  final String childId;

  const ChildHomePage({super.key, required this.childId});

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  final ChatService _chatService = ChatService(); // added for message
  bool hasUnreadMessages = false; // for messaging
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  String childName = '';
  String? childImage;
  String childGender = "girl";

  /// DYNAMIC COLORS
  Color get primaryColor {
    final child_gender = childGender.toString().toLowerCase();
    if (child_gender == "boy") {
      return const Color(0xFF6EC6FF);
    }
    return const Color(0xFFFF7A8A);
  }

  Color get secondaryColor {
    final child_gender = childGender.toString().toLowerCase();
    if (child_gender == "boy") {
      return const Color(0xFF4FA3E3);
    }
    return const Color(0xFFFFA6B3);
  }

  @override
  void initState() {
    super.initState();
    loadChildData();
    listenForMessages();
  }

  Future<void> loadChildData() async {
    try {
      debugPrint("Child ID: ${widget.childId}");

      final response = await supabase
          .from('child')
          .select()
          .eq('child_id', widget.childId)
          .single();

      debugPrint("FULL RESPONSE: $response");

      setState(() {
        childName = response['child_name']?.toString() ?? 'Hero';
        childImage = response['child_pic']?.toString();
        childGender = response['child_gender']?.toString() ?? 'girl';
        isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR LOADING CHILD: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/cloud_walpaper.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color.fromARGB(115, 255, 255, 255),
                BlendMode.lighten,
              ),
            ),
          ),
          child: SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        /// HEADER SECTION
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              209,
                              231,
                              243,
                            ).withOpacity(0.90),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFF3D56B),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChildProfilePage(
                                        childId: widget.childId,
                                      ),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      childImage != null &&
                                          childImage!.isNotEmpty
                                      ? NetworkImage(childImage!)
                                      : null,
                                  child:
                                      childImage == null || childImage!.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 30,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: childName,
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          color: primaryColor,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: "'s World",
                                        style: TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFF4C542),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ActivityPage(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.75),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.history,
                                        size: 24,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatPage(
                                            receiverId:
                                                AppSession.parentId ?? "",
                                            receiverName: "Parent",
                                          ),
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.75,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.chat_bubble_outline,
                                            size: 24,
                                            color: primaryColor,
                                          ),
                                        ),
                                        if (hasUnreadMessages)
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        /// BUTTON GRID SECTION
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.25,
                          children: [
                            DashboardButton(
                              title: "My Tasks",
                              icon: Icons.check_circle_outline,
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ChildTasksPage(),
                                  ),
                                );
                              },
                            ),
                            DashboardButton(
                              title: "Plant Buddy",
                              icon: Icons.local_florist,
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlantAIScreen(),
                                  ),
                                );
                              },
                            ),
                            DashboardButton(
                              title: "Study Timer",
                              icon: Icons.timer_outlined,
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudyTimerPage(),
                                  ),
                                );
                              },
                            ),
                            DashboardButton(
                              title: "Info Of The Day",
                              icon: Icons.lightbulb_outline,
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InformationOfDayPage(
                                      childId: widget.childId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            DashboardButton(
                              title: "Water Tracker",
                              icon: Icons.water_drop_rounded,
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WaterTrackerApp(
                                      childId: widget.childId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            DashboardButton(
                              title: "Help",
                              icon: Icons.favorite_outline,
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TaskHeroHelpPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // Added Log Out UI Section
                        const SizedBox(height: 30),

                        Center(
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFFA9CDE3),
                                  title: const Text("Log Out"),
                                  content: const Text(
                                    "Are you sure you want to log out?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("No"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await supabase.auth.signOut();

                                        if (!mounted) return;

                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SplashScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                      child: const Text("Yes"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              "Log Out",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void listenForMessages() {
    FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: AppSession.userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              hasUnreadMessages = snapshot.docs.isNotEmpty;
            });
          }
        });
  }
}

class DashboardButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color secondaryColor;

  const DashboardButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFA9D2E8), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: secondaryColor),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}