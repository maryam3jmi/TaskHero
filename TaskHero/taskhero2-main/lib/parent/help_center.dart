import 'package:flutter/material.dart';
import 'package:taskhero/parent/ParentProgressScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  bool isFaqSelected = true;

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@TaskHero.com',
      query: 'subject=Support Request: TaskHero',
    );
    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw Exception('Could not launch email');
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '0535535625');
    try {
      if (!await launchUrl(phoneUri)) {
        throw Exception('Could not launch phone');
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBDE0FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
       leading: IconButton(
  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ParentProgressScreen(),
      ),
    );
  },
),
       
        title: const Text(
          "Help Center",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // The search bar padding and TextField have been removed from here
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      "FAQ",
                      isFaqSelected,
                      () => setState(() => isFaqSelected = true),
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      "Contact Us",
                      !isFaqSelected,
                      () => setState(() => isFaqSelected = false),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isFaqSelected ? _buildFaqList() : _buildContactUsView(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 20, top: 10),
        child: Text(
          "© taskHero 2026",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String title, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFD166) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: active ? Colors.black : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      children: [
        _buildExpansionTile(
          "Getting Started",
          "Begin your journey with TaskHero by creating your account and setting clear, meaningful goals. Start adding your daily tasks and build consistent habits that support your long-term success.",
        ),
        _buildExpansionTile(
          "Tasks ",
          "Efficiently manage your responsibilities by organizing tasks, setting priorities, and monitoring your progress. TaskHero helps you stay focused and productive throughout your day.",
        ),
        _buildExpansionTile(
          "Rewards & Goals",
          "Stay motivated by setting achievable goals and earning rewards as you complete tasks. Track your progress, celebrate your accomplishments, and maintain momentum toward continuous improvement.",
        ),
      ],
    );
  }

  Widget _buildExpansionTile(String title, String content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: const TextStyle(height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactUsView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.support_agent, size: 100, color: Colors.orangeAccent),
        const SizedBox(height: 30),
        _buildContactItem(
          Icons.email_outlined,
          "Email Support",
          "support@taskhero.com",
          _launchEmail,
        ),
        const SizedBox(height: 15),
        _buildContactItem(
          Icons.phone_android_outlined,
          "Phone Support",
          "+966 535535625",
          _launchPhone,
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: const Text(
            "We are here to help!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
