import 'package:flutter/material.dart';
import 'package:wenest_app/utils/constants.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int _expandedIndex = -1;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I verify my real estate agency?',
      'answer':
          'To verify your agency, go to your profile and select "Verify Agency". You\'ll need to provide your RC number, business registration documents, and office address proof. Our team will review your submission within 3-5 business days.'
    },
    {
      'question': 'What are the fees for using WeNest?',
      'answer':
          'WeNest is free for property seekers. Agencies pay a monthly subscription fee based on their package tier. Premium listings and featured placements incur additional costs.'
    },
    {
      'question': 'How do I report a suspicious listing or user?',
      'answer':
          'You can report any suspicious activity by clicking the "Report" button on any listing or user profile. Our moderation team will investigate and take appropriate action.'
    },
    {
      'question': 'How do I reset my password?',
      'answer':
          'On the login screen, tap "Forgot Password" and enter your email address. We\'ll send you a password reset link. Follow the instructions to create a new password.'
    },
    {
      'question': 'Can I list properties as an individual landlord?',
      'answer':
          'Yes, individual landlords can list properties directly. Simply register as a landlord during signup and follow the property listing process.'
    },
    {
      'question': 'How do I contact a property agent?',
      'answer':
          'Each property listing has a "Contact Agent" button. Tap it to start a conversation through our secure messaging system.'
    },
    {
      'question': 'What makes an agency "verified"?',
      'answer':
          'Verified agencies have undergone our rigorous verification process, including RC number validation, physical address confirmation, and document verification. They receive a blue checkmark badge.'
    },
    {
      'question': 'How do I update my profile information?',
      'answer':
          'Go to your profile screen and tap the edit icon. You can update your personal information, profile picture, and contact details.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Find answers to common questions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      faq['question']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    initiallyExpanded: _expandedIndex == index,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedIndex = expanded ? index : -1;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(faq['answer']!),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Still need help?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Our support team is ready to assist you with any questions not covered here.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to help and support
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Contact Support',
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
          ],
        ),
      ),
    );
  }
}