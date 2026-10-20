import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:google_fonts/google_fonts.dart';

import 'mood_sheet.dart';

import 'wellness_screen.dart';

import 'chatbot_screen.dart';

import 'analytics_screen.dart';

import 'profile_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isLoading = true;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // We just stop the loading spinner instantly now since everything is real-time!

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // --- THE NEW DASHBOARD LAYOUT (BLOOD APP STYLE) ---

  Widget _buildHomeBody() {
    final hour = DateTime.now().hour;

    String greeting =
        hour < 12
            ? "Good morning"
            : hour < 17
            ? "Good afternoon"
            : "Good evening";

    return Container(
      width: double.infinity,

      height: double.infinity,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,

          end: Alignment.bottomCenter,

          colors: [Color(0xFFE0F4F1), Color(0xFFB5EADF), Color(0xFF8DE4D3)],
        ),
      ),

      child: SafeArea(
        child: Column(
          children: [
            // --- INCREASED TOP PADDING HERE! ---
            const SizedBox(
              height: 48,
            ), // Changed from 16 to 48 for beautiful spacing
            // --- TOP HEADER ROW ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // 1. ZENnie Left Oval
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,

                    child: Container(
                      height: 75,

                      width: 130,

                      alignment: Alignment.center,

                      padding: const EdgeInsets.only(left: 16, right: 8),

                      decoration: const BoxDecoration(
                        color: Color(0xFFFDFBF7),

                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(40),

                          bottomRight: Radius.circular(40),
                        ),
                      ),

                      child: Image.asset(
                        'assets/name.png',

                        height: 28,

                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // 2. Center Greetings
                StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .snapshots(),

                  builder: (context, snapshot) {
                    String displayName = "Loading...";

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;

                      if (data != null && data.containsKey('name')) {
                        displayName = data['name'];
                      } else {
                        String emailPrefix =
                            FirebaseAuth.instance.currentUser?.email?.split(
                              '@',
                            )[0] ??
                            "User";

                        displayName =
                            emailPrefix[0].toUpperCase() +
                            emailPrefix.substring(1);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),

                      child: Column(
                        children: [
                          Text(
                            greeting,

                            style: GoogleFonts.nunito(
                              fontSize: 15,

                              color: Colors.blueGrey.shade800,

                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            displayName,

                            style: GoogleFonts.nunito(
                              fontSize: 17,

                              fontWeight: FontWeight.w800,

                              color: Colors.blueGrey.shade900,

                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 3. Right Counsellor Oval
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,

                    child: GestureDetector(
                      onTap: () async {
                        const url =
                            'https://docs.google.com/forms/d/e/1FAIpQLScLu95CwH8IFSmIZp4qgE-iDiHNGbP4807bNlYMcxZYxLV2kQ/viewform';

                        final uri = Uri.parse(url);

                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,

                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },

                      child: Container(
                        height: 75,

                        width: 130,

                        alignment: Alignment.center,

                        padding: const EdgeInsets.only(left: 8, right: 16),

                        decoration: const BoxDecoration(
                          color: Color(0xFFFDFBF7),

                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),

                            bottomLeft: Radius.circular(40),
                          ),
                        ),

                        child: Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            const Icon(
                              Icons.support_agent_rounded,

                              color: Color(0xFF00796B),

                              size: 26,
                            ),

                            const SizedBox(height: 2),

                            Text(
                              "Counsellor",

                              style: GoogleFonts.nunito(
                                color: const Color(0xFF00796B),

                                fontSize: 11,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 2),

            // --- MIDDLE STREAK WORDING ---
            Text(
              "You are on a",

              style: GoogleFonts.nunito(
                fontSize: 18,

                fontWeight: FontWeight.bold,

                color: Colors.blueGrey.shade900,
              ),
            ),

            // --- THE FIX: LIVE STREAK UPDATES ---
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),

              builder: (context, snapshot) {
                int currentStreak = 0;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;

                  if (data != null && data.containsKey('streak')) {
                    currentStreak = data['streak'];
                  }
                }

                return Text(
                  "$currentStreak",

                  style: GoogleFonts.mulish(
                    fontSize: 80,

                    fontWeight: FontWeight.w900,

                    color: Colors.blueGrey.shade900,

                    height: 1.1,

                    letterSpacing: -2,
                  ),
                );
              },
            ),

            Text(
              "Day Streak!",

              style: GoogleFonts.nunito(
                fontSize: 18,

                fontWeight: FontWeight.bold,

                color: Colors.blueGrey.shade900,
              ),
            ),

            const Spacer(flex: 1),

            // --- THE ANIMATED CHARACTER ---
            _isLoading
                ? const CircularProgressIndicator(color: Colors.teal)
                : const AnimatedZennie(),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeBody(),

      const WellnessScreen(),

      const ChatbotScreen(),

      const AnalyticsScreen(),

      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,

      body: IndexedStack(index: _currentIndex, children: pages),

      // --- BIG FLOATING ACTION BUTTON ---
      floatingActionButton:
          _currentIndex == 0
              ? SizedBox(
                height: 70,

                width: 70,

                child: FloatingActionButton(
                  shape: const CircleBorder(),

                  backgroundColor: const Color(0xFF00796B),

                  elevation: 4,

                  child: const Icon(Icons.add, color: Colors.white, size: 38),

                  onPressed:
                      () => showModalBottomSheet(
                        context: context,

                        isScrollControlled: true,

                        backgroundColor: Colors.transparent,

                        builder: (context) => const MoodSheet(),
                      ),
                ),
              )
              : null,

      // --- THICKER FLOATING NAVIGATION BAR ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),

        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(35),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),

                blurRadius: 20,

                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),

            child: BottomNavigationBar(
              currentIndex: _currentIndex,

              onTap: (index) => setState(() => _currentIndex = index),

              type: BottomNavigationBarType.fixed,

              backgroundColor: Colors.white,

              selectedItemColor: const Color(0xFF00796B),

              unselectedItemColor: Colors.grey.shade400,

              iconSize: 28,

              showSelectedLabels: true,

              showUnselectedLabels: true,

              selectedLabelStyle: GoogleFonts.nunito(
                fontSize: 12,

                fontWeight: FontWeight.bold,
              ),

              unselectedLabelStyle: GoogleFonts.nunito(
                fontSize: 12,

                fontWeight: FontWeight.w600,
              ),

              elevation: 0,

              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 6),

                    child: Icon(Icons.home_rounded),
                  ),

                  label: 'Home',
                ),

                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 6),

                    child: Icon(Icons.spa_rounded),
                  ),

                  label: 'Wellness',
                ),

                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 6),

                    child: Icon(Icons.chat_bubble_rounded),
                  ),

                  label: 'ZENnie',
                ),

                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 6),

                    child: Icon(Icons.bar_chart_rounded),
                  ),

                  label: 'Insights',
                ),

                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 6),

                    child: Icon(Icons.person_rounded),
                  ),

                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================

// THE MAGIC FLOATING ANIMATION WIDGET

// =====================================================================

class AnimatedZennie extends StatefulWidget {
  const AnimatedZennie({super.key});

  @override
  State<AnimatedZennie> createState() => _AnimatedZennieState();
}

class _AnimatedZennieState extends State<AnimatedZennie>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,

      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -15,

      end: 15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,

      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),

          child: Image.asset(
            'assets/zennie.png',

            height: MediaQuery.of(context).size.height * 0.35,

            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}
