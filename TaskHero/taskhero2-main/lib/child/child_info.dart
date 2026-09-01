import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InformationOfDayPage extends StatefulWidget {
  final String childId;

  const InformationOfDayPage({
    super.key,
    required this.childId,
  });

  @override
  State<InformationOfDayPage> createState() =>
      _InformationOfDayPageState();
}

class _InformationOfDayPageState
    extends State<InformationOfDayPage> {
  final supabase = Supabase.instance.client;

  String? childImage;
  String? informationImage;
  String? informationText;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInformationOfDay();
  }

  Future<void> fetchInformationOfDay() async {
    try {
      final response = await supabase
          .from('child')
          .select('child_pic')
          .eq('child_id', widget.childId)
          .single();

      childImage =
          response['child_pic']?.toString();

      final informationResponse =
          await supabase
              .from('information')
              .select();

      final today = DateTime.now();

      final seed =
          today.year +
          today.month +
          today.day;

      final random = Random(seed);

      final randomIndex = random.nextInt(
        informationResponse.length,
      );

      final todayInformation =
          informationResponse[randomIndex];

      informationImage =
          todayInformation['information_image']
              ?.toString();

      informationText =
          todayInformation['information_text']
              ?.toString();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Error fetching information: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final screenHeight =
        MediaQuery.of(context).size.height;

    final isTablet =
        screenWidth > 700;

    return Scaffold(
      backgroundColor:
          const Color(0xFFD5ECFF),

      body: SafeArea(
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : Padding(
                padding:
                    const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder:
                      (context, constraints) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            const Spacer(),

                            Text(
                              'Information of the day',
                              style: TextStyle(
                                fontSize:
                                    isTablet
                                        ? 30
                                        : 22,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    const Color(
                                  0xFF2D2D2D,
                                ),
                              ),
                            ),

                            const Spacer(),

                            CircleAvatar(
                              radius:
                                  isTablet
                                      ? 30
                                      : 22,
                              backgroundColor:
                                  Colors.white,
                              backgroundImage:
                                  childImage !=
                                          null
                                      ? NetworkImage(
                                          childImage!,
                                        )
                                      : null,
                            ),
                          ],
                        ),

                        SizedBox(
                          height:
                              isTablet
                                  ? 30
                                  : 20,
                        ),

                        Container(
                          width:
                              isTablet
                                  ? 380
                                  : screenWidth *
                                      0.55,
                          height:
                              isTablet
                                  ? 300
                                  : screenHeight *
                                      0.25,
                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                              24,
                            ),
                          ),
                          clipBehavior:
                              Clip.hardEdge,
                          child:
                              informationImage !=
                                          null &&
                                      informationImage!
                                          .isNotEmpty
                                  ? Image.network(
                                      informationImage!,
                                      fit:
                                          BoxFit.cover,
                                    )
                                  : const Center(
                                      child:
                                          CircularProgressIndicator(),
                                    ),
                        ),

                        SizedBox(
                          height:
                              isTablet
                                  ? 30
                                  : 20,
                        ),

                        Expanded(
                          child: Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  24,
                              vertical: 28,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                28,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Did you know?',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        isTablet
                                            ? 40
                                            : 30,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        const Color(
                                      0xFF2D2D2D,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 20,
                                ),

                                Expanded(
                                  child:
                                      SingleChildScrollView(
                                    child: Text(
                                      informationText ??
                                          '',
                                      textAlign:
                                          TextAlign
                                              .center,
                                      style:
                                          TextStyle(
                                        fontSize:
                                            isTablet
                                                ? 40
                                                : 17,
                                        height:
                                            1.6,
                                        fontWeight:
                                            FontWeight
                                                .w500,
                                        color:
                                            const Color(
                                          0xFF444444,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        SizedBox(
                          width:
                              isTablet
                                  ? 320
                                  : 280,
                          height: 60,
                          child:
                              ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFFFFE15A,
                              ),
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),
                            ),
                            child: Text(
                              'Got it!',
                              style: TextStyle(
                                fontSize:
                                    isTablet
                                        ? 28
                                        : 24,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    const Color(
                                  0xFF2D2D2D,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
