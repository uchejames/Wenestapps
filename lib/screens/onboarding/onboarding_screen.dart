import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "image": AppAssets.onboarding1,
      "title": "Discover Homes Easily",
      "subtitle": "Find your dream home with verified listings\ntailored to your needs.",
    },
    {
      "image": AppAssets.onboarding2,
      "title": "Connect with Agents",
      "subtitle": "Chat directly with trusted agents, landlords,\nand agencies*",
    },
    {
      "image": AppAssets.onboarding3,
      "title": "Rent, Buy & Sell with\nConfidence",
      "subtitle": "",
    },
  ];

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/role_selection');
    }
  }

  void _skipOnboarding() {
    Navigator.pushReplacementNamed(context, '/role_selection');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: true,
          bottom: true,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => _buildOnboardingPage(_onboardingData[index]),
              ),

              Positioned(
                top: 20,
                right: 20,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, dynamic> data) {
    final isLastPage = _currentPage == _onboardingData.length - 1;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(data["image"]),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Deep teal overlay
        Container(color: AppColors.primaryColor.withOpacity(0.45)),

        // Bottom gradient
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.primaryColor.withOpacity(0.98)],
                stops: const [0.0, 0.65],
              ),
            ),
          ),
        ),

        SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data["title"],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -0.5,
                      shadows: [Shadow(offset: Offset(0, 3), blurRadius: 10, color: Colors.black54)],
                    ),
                  ),

                  if (data["subtitle"].isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      data["subtitle"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 16.5, height: 1.6),
                    ),
                  ],

                  const SizedBox(height: 80),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _onboardingData.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            margin: const EdgeInsets.only(right: 10),
                            height: 9,
                            width: i == _currentPage ? 32 : 9,
                            decoration: BoxDecoration(
                              color: i == _currentPage ? AppColors.secondaryColor : Colors.white38,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: _nextPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: isLastPage ? 180 : 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: isLastPage ? AppColors.secondaryColor : Colors.white.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(33),
                            boxShadow: isLastPage
                                ? [BoxShadow(color: AppColors.accentColor.withOpacity(0.5), blurRadius: 18, offset: const Offset(0, 8))]
                                : null,
                          ),
                          child: Center(
                            child: isLastPage
                                ? const Text(
                                    'Get Started',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                                  )
                                : const Icon(Icons.chevron_right, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}