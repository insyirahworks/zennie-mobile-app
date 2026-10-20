import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ADDED THIS IMPORT
import 'login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // The content for your 3 onboarding screens
  final List<Map<String, dynamic>> _pages = [
    {
      "icon": Icons.mood_rounded,
      "title": "Track Your Wellbeing",
      "description":
          "Log your daily moods and discover patterns in managing your emotions.",
    },
    {
      "icon": Icons.auto_awesome_rounded,
      "title": "Meet ZENnie",
      "description":
          "Your judgment-free AI companion, ready to listen and support you whenever you feel overwhelmed.",
    },
    {
      "icon": Icons.map_rounded,
      "title": "Campus Wellness",
      "description":
          "Discover tailored, various activities around UNIMAS to help you relax and recharge.",
    },
  ];

  // MADE THIS FUNCTION ASYNC TO SAVE TO MEMORY
  Future<void> _onNextTap() async {
    if (_currentPage == _pages.length - 1) {
      // --- THE MAGIC MEMORY SAVER ---
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showHome', true);

      // Safety check to ensure the screen is still visible before navigating
      if (!mounted) return;

      // THIS REPLACES THE SCREEN SO THEY CAN'T SWIPE BACK TO ONBOARDING
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // --- YOUR SIGNATURE MINT GRADIENT ---
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8DE4D3), Color(0xFFB5EADF), Color(0xFFF4FBF9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- SKIP BUTTON ---
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    // Skip right to the end
                    _pageController.animateToPage(
                      _pages.length - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // --- SWIPEABLE PAGES ---
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Giant Soft Icon
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              _pages[index]["icon"],
                              size: 100,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          const SizedBox(height: 60),

                          // Title
                          Text(
                            _pages[index]["title"],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            _pages[index]["description"],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.teal.shade900.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // --- BOTTOM NAVIGATION AREA ---
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    // Dot Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color:
                                _currentPage == index
                                    ? Colors.teal.shade700
                                    : Colors.teal.shade700.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Next / Get Started Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onNextTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade800,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? "Get Started"
                              : "Next",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
