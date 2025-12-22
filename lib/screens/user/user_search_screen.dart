import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest/utils/constants.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final List<Map<String, dynamic>> _properties = [
    {
      'title': '3 Bedroom Apartment',
      'location': 'Lekki, Lagos',
      'price': '₦8,000,000',
      'bedrooms': 3,
      'bathrooms': 2,
      'area': '180 sqm',
      'imageUrl': '',
      'isFeatured': true,
    },
    {
      'title': 'Luxury Duplex',
      'location': 'Ikoyi, Lagos',
      'price': '₦15,000,000',
      'bedrooms': 4,
      'bathrooms': 4,
      'area': '320 sqm',
      'imageUrl': '',
      'isFeatured': true,
    },
    {
      'title': 'Mini Flat',
      'location': 'Surulere, Lagos',
      'price': '₦3,500,000',
      'bedrooms': 1,
      'bathrooms': 1,
      'area': '45 sqm',
      'imageUrl': '',
      'isFeatured': false,
    },
    {
      'title': 'Office Space',
      'location': 'Victoria Island, Lagos',
      'price': '₦2,500,000/year',
      'bedrooms': 0,
      'bathrooms': 2,
      'area': '200 sqm',
      'imageUrl': '',
      'isFeatured': false,
    },
    {
      'title': '5 Bedroom Mansion',
      'location': 'Banana Island, Lagos',
      'price': '₦50,000,000',
      'bedrooms': 5,
      'bathrooms': 6,
      'area': '800 sqm',
      'imageUrl': '',
      'isFeatured': true,
    },
  ];

  bool _isLoading = false;

  Future<void> _refreshProperties() async {
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
        title: const Text('Search Properties'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProperties,
        child: Column(
          children: [
            // Search filters
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: AppColors.backgroundColor,
              ),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by location, property type...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', true),
                        const SizedBox(width: 10),
                        _buildFilterChip('Apartments', false),
                        const SizedBox(width: 10),
                        _buildFilterChip('Houses', false),
                        const SizedBox(width: 10),
                        _buildFilterChip('Land', false),
                        const SizedBox(width: 10),
                        _buildFilterChip('Commercial', false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Additional filters
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Show price filter
                          },
                          icon: const Icon(Icons.attach_money),
                          label: const Text('Price'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Show bedrooms filter
                          },
                          icon: const Icon(Icons.bed),
                          label: const Text('Bedrooms'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Show more filters
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('More'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Properties list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? _buildShimmerList()
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 1.8,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: _properties.length,
                        itemBuilder: (context, index) {
                          final property = _properties[index];
                          return _buildPropertyCard(property);
                        },
                      ),
              ),
            ),
          ],
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

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.house,
                      size: 50,
                      color: AppColors.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                  if (property['isFeatured'])
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Property details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        property['location'],
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  property['price'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (property['bedrooms'] > 0)
                      Row(
                        children: [
                          const Icon(Icons.bed, size: 16, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text('${property['bedrooms']} bed'),
                        ],
                      ),
                    if (property['bathrooms'] > 0)
                      Row(
                        children: [
                          const Icon(Icons.bathtub,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text('${property['bathrooms']} bath'),
                        ],
                      ),
                    Row(
                      children: [
                        const Icon(Icons.square_foot,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(property['area']),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.8,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property image placeholder
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title placeholder
                      Container(
                        height: 20,
                        width: 150,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      // Location placeholder
                      Container(
                        height: 15,
                        width: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      // Price placeholder
                      Container(
                        height: 20,
                        width: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      // Features row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 15,
                            width: 50,
                            color: Colors.white,
                          ),
                          Container(
                            height: 15,
                            width: 50,
                            color: Colors.white,
                          ),
                          Container(
                            height: 15,
                            width: 50,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
