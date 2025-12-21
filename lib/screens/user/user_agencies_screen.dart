import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest_app/utils/constants.dart';

class UserAgenciesScreen extends StatefulWidget {
  const UserAgenciesScreen({super.key});

  @override
  State<UserAgenciesScreen> createState() => _UserAgenciesScreenState();
}

class _UserAgenciesScreenState extends State<UserAgenciesScreen> {
  final List<Map<String, dynamic>> _agencies = [
    {
      'name': 'Premium Estates Ltd',
      'rating': 4.8,
      'reviewCount': 124,
      'verified': true,
      'properties': 42,
      'specialty': 'Luxury Apartments',
    },
    {
      'name': 'Urban Homes Agency',
      'rating': 4.5,
      'reviewCount': 89,
      'verified': true,
      'properties': 28,
      'specialty': 'Affordable Housing',
    },
    {
      'name': 'Metropolitan Properties',
      'rating': 4.7,
      'reviewCount': 156,
      'verified': true,
      'properties': 67,
      'specialty': 'Commercial Spaces',
    },
    {
      'name': 'Green Valley Realtors',
      'rating': 4.3,
      'reviewCount': 76,
      'verified': false,
      'properties': 15,
      'specialty': 'Residential Homes',
    },
    {
      'name': 'Skyline Property Group',
      'rating': 4.9,
      'reviewCount': 203,
      'verified': true,
      'properties': 89,
      'specialty': 'Penthouse Suites',
    },
  ];

  bool _isLoading = false;

  Future<void> _refreshAgencies() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verified Agencies'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAgencies,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search agencies...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', true),
                    const SizedBox(width: 10),
                    _buildFilterChip('Verified Only', false),
                    const SizedBox(width: 10),
                    _buildFilterChip('Highest Rated', false),
                    const SizedBox(width: 10),
                    _buildFilterChip('Most Properties', false),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Agencies list
              Expanded(
                child: _isLoading
                    ? _buildShimmerList()
                    : ListView.builder(
                        itemCount: _agencies.length,
                        itemBuilder: (context, index) {
                          final agency = _agencies[index];
                          return _buildAgencyCard(agency);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryColor,
      onSelected: (selected) {
        // Handle filter selection
      },
    );
  }

  Widget _buildAgencyCard(Map<String, dynamic> agency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              agency['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (agency['verified'])
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        agency['specialty'],
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text('${agency['rating']}'),
                    const SizedBox(width: 5),
                    Text(
                      '(${agency['reviewCount']} reviews)',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Text('${agency['properties']} properties'),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // View agency details
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 20,
                              width: 150,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 15,
                              width: 100,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 15,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 15,
                    width: 80,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
