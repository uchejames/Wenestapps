import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/models/agency.dart';
// ============ SUBSCRIPTION SCREEN ============

class SubscriptionScreen extends StatefulWidget {
  final Agency agency;

  const SubscriptionScreen({super.key, required this.agency});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = 'basic';

  final Map<String, Map<String, dynamic>> _plans = {
    'basic': {
      'name': 'Basic',
      'price': 15000,
      'duration': '30 days',
      'features': [
        'Up to 10 property listings',
        'Basic analytics',
        'Email support',
        'Standard visibility',
      ],
      'color': Colors.blue,
    },
    'professional': {
      'name': 'Professional',
      'price': 35000,
      'duration': '30 days',
      'features': [
        'Up to 50 property listings',
        'Advanced analytics',
        'Priority support',
        'Featured listings (5/month)',
        'Agent management',
        'Premium visibility',
      ],
      'color': AppColors.primaryColor,
      'popular': true,
    },
    'enterprise': {
      'name': 'Enterprise',
      'price': 75000,
      'duration': '30 days',
      'features': [
        'Unlimited property listings',
        'Full analytics suite',
        '24/7 priority support',
        'Unlimited featured listings',
        'Unlimited agents',
        'Maximum visibility',
        'Custom branding',
        'API access',
      ],
      'color': AppColors.accentColor,
    },
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Plan Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.lightTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Plan',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Professional Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Renews on January 15, 2025',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '23 days remaining',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Available Plans
          const Text(
            'Available Plans',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the plan that fits your needs',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          
          // Plan Cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _plans.length,
            itemBuilder: (context, index) {
              final planKey = _plans.keys.elementAt(index);
              final plan = _plans[planKey]!;
              final isSelected = _selectedPlan == planKey;
              final isPopular = plan['popular'] == true;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPlan = planKey),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? plan['color'] : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: (plan['color'] as Color).withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  plan['name'],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: plan['color'],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: (plan['color'] as Color).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: plan['color'],
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₦${plan['price'].toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  )}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '/ ${plan['duration']}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ...((plan['features'] as List<String>).map((feature) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: plan['color'],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })),
                          ],
                        ),
                      ),
                      if (isPopular)
                        Positioned(
                          top: 0,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: plan['color'],
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Upgrade Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handle subscription upgrade
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Upgrade Plan'),
                    content: Text(
                      'Upgrade to ${_plans[_selectedPlan]!['name']} plan for ₦${_plans[_selectedPlan]!['price']}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Plan upgraded successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _plans[_selectedPlan]!['color'],
              ),
              child: const Text('Upgrade Plan', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}