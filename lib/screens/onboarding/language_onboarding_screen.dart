import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/screens/onboarding/onboarding_screen.dart';

class LanguageOnboardingScreen extends StatefulWidget {
  const LanguageOnboardingScreen({super.key});

  @override
  State<LanguageOnboardingScreen> createState() =>
      _LanguageOnboardingScreenState();
}

class _LanguageOnboardingScreenState extends State<LanguageOnboardingScreen> {
  String _selectedLanguage = 'English';

  final List<String> _languages = [
    'English',
    'Yoruba',
    'Igbo',
    'Hausa',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose your preferred language',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView.builder(
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final language = _languages[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: Text(
                        language,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: _selectedLanguage == language
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: _selectedLanguage == language
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primaryColor,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedLanguage = language;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to main onboarding screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}