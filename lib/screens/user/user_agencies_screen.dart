import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agency.dart';

class UserAgenciesScreen extends StatefulWidget {
  const UserAgenciesScreen({super.key});

  @override
  State<UserAgenciesScreen> createState() => _UserAgenciesScreenState();
}

class _UserAgenciesScreenState extends State<UserAgenciesScreen> {
  final _supabaseService = SupabaseService();
  final _searchController = TextEditingController();
  
  List<Agency> _agencies = [];
  List<Agency> _filteredAgencies = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAgencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAgencies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final agencies = await _supabaseService.getAgencies(
        verified: _selectedFilter == 'Verified Only' ? true : null,
      );

      setState(() {
        _agencies = agencies;
        _filteredAgencies = agencies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading agencies: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _refreshAgencies() async {
    await _loadAgencies();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadAgencies();
  }

  void _filterAgencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAgencies = _agencies;
      } else {
        _filteredAgencies = _agencies.where((agency) {
          return agency.name.toLowerCase().contains(query.toLowerCase()) ||
                 (agency.city?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (agency.state?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Verified Agencies',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAgencies,
        color: AppColors.primaryColor,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search agencies...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: _filterAgencies,
                ),
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip('All', _selectedFilter == 'All'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Verified Only', _selectedFilter == 'Verified Only'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Highest Rated', _selectedFilter == 'Highest Rated'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Most Properties', _selectedFilter == 'Most Properties'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_filteredAgencies.length} agencies found',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Agencies List
            Expanded(
              child: _isLoading
                  ? _buildShimmerList()
                  : _filteredAgencies.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _filteredAgencies.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < _filteredAgencies.length - 1 ? 16 : 0,
                              ),
                              child: _buildAgencyCard(_filteredAgencies[index]),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAgencyCard(Agency agency) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/agency_detail',
          arguments: agency.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Agency Logo
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: agency.logoUrl != null
                        ? Image.network(
                            agency.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.business_rounded,
                                color: AppColors.primaryColor,
                                size: 35,
                              );
                            },
                          )
                        : const Icon(
                            Icons.business_rounded,
                            color: AppColors.primaryColor,
                            size: 35,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Agency Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              agency.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (agency.verified)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: AppColors.primaryColor,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (agency.city != null && agency.state != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${agency.city}, ${agency.state}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.home_work_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '120+ Properties',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (agency.description != null) ...[
              const SizedBox(height: 14),
              Text(
                agency.description!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            // Contact Info Row
            Row(
              children: [
                if (agency.contactPhone != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 15,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            agency.contactPhone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (agency.contactPhone != null && agency.contactEmail != null)
                  Container(
                    width: 1,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.grey.shade300,
                  ),
                if (agency.contactEmail != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_rounded,
                          size: 15,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            agency.contactEmail!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // View Details Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/agency_detail',
                    arguments: agency.id,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 15,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          const Text(
            'No agencies found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Try adjusting your search',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}