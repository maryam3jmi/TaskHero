import 'package:flutter/material.dart';
import 'package:taskhero/parent/ParentProgressScreen.dart';
import 'reports_services.dart';

class MockReportScreen extends StatefulWidget {
  const MockReportScreen({super.key});

  @override
  State<MockReportScreen> createState() => _MockReportScreenState();
}

class _MockReportScreenState extends State<MockReportScreen> {
  final ReportService _reportService = ReportService();

  String? selectedChildId;
  String selectedPeriod = "week";

  List<Map<String, dynamic>> childrenList = [];
  bool isLoadingChildren = true;
  Future<Map<String, dynamic>>? _childReportFuture;

  final List<Color> _avatarColors = [
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.blue.shade300,
    Colors.teal.shade300,
    Colors.pink.shade300,
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final children = await _reportService.getChildren();

      setState(() {
        childrenList = children;

        if (childrenList.isNotEmpty) {
          selectedChildId = childrenList[0]['child_id'].toString();
          _updateReportFuture();
        }

        isLoadingChildren = false;
      });
    } catch (e) {
      debugPrint("Database Error fetching children: $e");
      setState(() {
        isLoadingChildren = false;
      });
    }
  }

  void _updateReportFuture() {
    if (selectedChildId != null) {
      _childReportFuture = _reportService.getChildReport(
        selectedChildId!,
        selectedPeriod,
      );
    }
  }

  Color _getAvatarColor(String id) {
    int hash = id.hashCode;
    return _avatarColors[hash.abs() % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDF3FF),
      body: SafeArea(
        child: isLoadingChildren
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  /// HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ParentProgressScreen(),
                              ),
                            );
                          },
                        ),
                        const Expanded(
        child: Text(
          "Reports",
          textAlign: TextAlign.center, // يضمن التوسط داخل المساحة المتاحة
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // 3. مساحة فارغة وهمية بنفس حجم زر العودة لخلق توازن مثالي في اليمين
      const SizedBox(width: 48), // الـ IconButton الافتراضي حجمه 48
    ],
  ),
),
                  /// DYNAMIC UNIQUE CHILDREN SLIDER
                  SizedBox(
                    height: 105,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: childrenList.length,
                      itemBuilder: (context, index) {
                        final child = childrenList[index];
                        final String cId = child['child_id'].toString();
                        final bool isSelected = selectedChildId == cId;
                        final String name = child['child_name'] ?? 'Child';
                        final String initial = name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'C';

                        return GestureDetector(
                          onTap: () {
                            if (selectedChildId != cId) {
                              setState(() {
                                selectedChildId = cId;
                                _updateReportFuture();
                              });
                            }
                          },
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 14),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.indigo
                                          : Colors.amber.shade400,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: _getAvatarColor(cId),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  /// METRIC DURATION SELECTORS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildPeriodButton("This week", "week"),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPeriodButton("This month", "month"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  /// COMPONENT CONTAINER STREAM
                  Expanded(
                    child: selectedChildId == null || _childReportFuture == null
                        ? const Center(child: Text("No Child Selected"))
                        : FutureBuilder<Map<String, dynamic>>(
                            future: _childReportFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text("Error: ${snapshot.error}"),
                                );
                              }

                              final data = snapshot.data;
                              if (data == null || data.isEmpty) {
                                return const Center(
                                  child: Text("No data found for this period."),
                                );
                              }

                              final totalPoints = data['totalPoints'] ?? 0;
                              final totalWater = data['totalWater'] ?? 0;

                              double completionPercent = 0.0;
                              final Map<String, dynamic> tasks =
                                  data['tasks'] ??
                                  {'completed': 0, 'total': 0, 'trend': 0.0};
                              if (tasks['total'] > 0) {
                                completionPercent =
                                    (tasks['completed'] / tasks['total']) * 100;
                              }

                              return SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Column(
                                  children: [
                                    _buildTaskCard(completionPercent, tasks),

                                    /// SUMMARY METRICS CARD
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD6F0FF),
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            children: [
                                              const Text(
                                                "Total Points",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "$totalPoints",
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              const Text(
                                                "Water Intake",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "$totalWater ml",
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    _buildRewardsCard(data['waterChart']),
                                    _buildFocusCard(data['focus']),
                                    _buildActivityCard(data['activity']),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPeriodButton(String text, String value) {
    final bool isSelected = selectedPeriod == value;

    return GestureDetector(
      onTap: () {
        if (selectedPeriod != value) {
          setState(() {
            selectedPeriod = value;
            _updateReportFuture();
          });
        }
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(double percent, Map<String, dynamic> taskData) {
    final double trend = (taskData['trend'] ?? 0.0).toDouble();
    final bool isPositive = trend >= 0;
    final String prefix = isPositive ? "+" : "";
    final Color trendColor = isPositive
        ? Colors.green.shade700
        : Colors.red.shade700;

    final String comparisonScope = selectedPeriod == "week"
        ? "last week"
        : "last month";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F0FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Task Completion",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 10,
                      color: Colors.lightGreen,
                      backgroundColor: Colors.green.shade100,
                    ),
                  ),
                  Text(
                    "${percent.toInt()}%",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${taskData['completed']} of ${taskData['total']} tasks completed",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "$prefix${trend.toStringAsFixed(0)}% completion rate from $comparisonScope",
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsCard(List<dynamic>? chartData) {
    if (chartData == null || chartData.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFD6F0FF),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: Text(
            "No water logs found in this period.",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    double maxValue = 10.0;
    for (var element in chartData) {
      final value = (element['value'] as num).toDouble();
      if (value > maxValue) maxValue = value;
    }

    final String cardTitle = selectedPeriod == "week"
        ? "Water Intake (Daily)"
        : "Water Intake (Monthly Blocks)";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F0FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.map<Widget>((item) {
              final double actualValue = (item['value'] as num).toDouble();

              double heightValue = 0.0;
              if (actualValue > 0) {
                double rawHeight = (actualValue / maxValue) * 90;
                heightValue = rawHeight < 8.0 ? 8.0 : rawHeight;
              }

              return Column(
                children: [
                  Text(
                    actualValue > 0 ? actualValue.toStringAsFixed(0) : "0",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: actualValue > 0
                          ? Colors.amber.shade900
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: selectedPeriod == "week" ? 30 : 45,
                    height: heightValue,
                    decoration: BoxDecoration(
                      color: actualValue > 0
                          ? Colors.amber
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['day'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusCard(List<dynamic>? focusData) {
    if (focusData == null || focusData.isEmpty) return const SizedBox.shrink();

    final List<Color> assignedColors = [
      Colors.green,
      Colors.blue,
      Colors.amber,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F0FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Focus Areas",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CustomPaint(
                  painter: PiePainter(focusData, assignedColors),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(focusData.length, (index) {
                    final item = focusData[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: LegendItem(
                        color: assignedColors[index % assignedColors.length],
                        text: item['type'] ?? 'Metric',
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(List<dynamic>? activitiesList) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F0FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Activity",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (activitiesList == null || activitiesList.isEmpty)
            const Center(child: Text("No logging actions yet."))
          else
            ...activitiesList.map((e) {
              final iconType = e['icon'] ?? 'task';
              Color iconBgColor = Colors.amber.shade100;
              Color iconColor = Colors.amber.shade800;
              IconData displayIcon = Icons.card_giftcard;

              if (iconType == 'task') {
                iconBgColor = Colors.green.shade100;
                iconColor = Colors.green;
                displayIcon = Icons.check_circle;
              } else if (iconType == 'water') {
                iconBgColor = Colors.blue.shade100;
                iconColor = Colors.blue;
                displayIcon = Icons.water_drop;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: iconBgColor,
                      child: Icon(displayIcon, color: iconColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e['subtitle'] ?? '',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class PiePainter extends CustomPainter {
  final List<dynamic> data;
  final List<Color> colors;
  PiePainter(this.data, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    double start = -1.57079632679;
    double total = 0.0;

    for (var e in data) {
      total += (e['value'] as num).toDouble();
    }
    if (total == 0) return;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweep = ((item['value'] as num).toDouble() / total) * 6.28318530718;
      if (sweep == 0) continue;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
