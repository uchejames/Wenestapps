import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agent.dart';
import 'package:wenest/models/property.dart';

class AgentPerformanceScreen extends StatefulWidget {
  final Agent agent;

  const AgentPerformanceScreen({super.key, required this.agent});

  @override
  State<AgentPerformanceScreen> createState() => _AgentPerformanceScreenState();
}

class _AgentPerformanceScreenState extends State<AgentPerformanceScreen> {
  final _supabaseService = SupabaseService();
  
  Map<String, dynamic> _stats = {};
  List<Property> _topProperties = [];
  bool _isLoading = true;
  String _selectedPeriod = '30';

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);
    try {
      // Load agent's properties
      final properties = await _supabaseService.getProperties(
        agentId: widget.agent.id,
        limit: 1000,
      );

      // Calculate stats
      final activeProperties = properties.where((p) => p.status == 'active').length;
      final totalViews = properties.fold<int>(0, (sum, p) => sum + p.viewsCount);
      final totalSaves = properties.fold<int>(0, (sum, p) => sum + p.savesCount);
      final totalInquiries = properties.fold<int>(0, (sum, p) => sum + p.inquiriesCount);
      final soldProperties = properties.where((p) => p.status == 'sold').length;
      final rentedProperties = properties.where((p) => p.status == 'rented').length;

      // Get top properties by views
      final sortedByViews = List<Property>.from(properties)
        ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));

      setState(() {
        _stats = {
          'total_properties': properties.length,
          'active_properties': activeProperties,
          'sold_properties': soldProperties,
          'rented_properties': rentedProperties,
          'total_views': totalViews,
          'total_saves': totalSaves,
          'total_inquiries': totalInquiries,
          'avg_views': properties.isNotEmpty ? totalViews / properties.length : 0,
        };
        _topProperties = sortedByViews.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPerformanceData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPerformanceData,
        color: AppColors.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(100),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
              else ...[
                _buildOverviewCard(),
                const SizedBox(height: 16),
                _buildPropertyStats(),
                const SizedBox(height: 16),
                _buildEngagementStats(),
                const SizedBox(height: 20),
                _buildTopPerformingProperties(),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Time Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: const [
                DropdownMenuItem(value: '7', child: Text('Last 7 days')),
                DropdownMenuItem(value: '30', child: Text('Last 30 days')),
                DropdownMenuItem(value: '90', child: Text('Last 90 days')),
                DropdownMenuItem(value: 'all', child: Text('All time')),
              ],
              onChanged: (value) {
                setState(() => _selectedPeriod = value!);
                _loadPerformanceData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final totalProperties = _stats['total_properties'] ?? 0;
    final activeProperties = _stats['active_properties'] ?? 0;
    final successRate = totalProperties > 0 
        ? (((_stats['sold_properties'] ?? 0) + (_stats['rented_properties'] ?? 0)) / totalProperties * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B4D3E),
            Color(0xFF2D6A58),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Performance Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewStat(
                  'Total Properties',
                  '$totalProperties',
                  Icons.home_work_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildOverviewStat(
                  'Active Listings',
                  '$activeProperties',
                  Icons.check_circle_outline,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildOverviewStat(
                  'Success Rate',
                  '$successRate%',
                  Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPropertyStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Properties',
                  '${_stats['total_properties'] ?? 0}',
                  Icons.home_work_outlined,
                  AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  '${_stats['active_properties'] ?? 0}',
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sold',
                  '${_stats['sold_properties'] ?? 0}',
                  Icons.sell_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rented',
                  '${_stats['rented_properties'] ?? 0}',
                  Icons.key_outlined,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engagement Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Views',
                  '${_stats['total_views'] ?? 0}',
                  Icons.visibility_outlined,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Saves',
                  '${_stats['total_saves'] ?? 0}',
                  Icons.favorite_outline,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Inquiries',
                  '${_stats['total_inquiries'] ?? 0}',
                  Icons.chat_bubble_outline,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg. Views',
                  ((_stats['avg_views'] ?? 0) as num).toDouble().toStringAsFixed(1),
                  Icons.analytics_outlined,
                  Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformingProperties() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Performing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (_topProperties.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Navigate to full properties list
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_topProperties.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 60,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Properties Yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add properties to see performance data',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _topProperties.asMap().entries.map((entry) {
                final index = entry.key;
                final property = entry.value;
                return _buildPropertyCard(property, index + 1);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property, int rank) {
    final Color rankColor = rank == 1 
        ? const Color(0xFFFFD700) // Gold
        : rank == 2 
            ? const Color(0xFFC0C0C0) // Silver
            : rank == 3
                ? const Color(0xFFCD7F32) // Bronze
                : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/property_detail',
              arguments: property.id,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Property thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: property.media.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            property.media.first.fileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.home_rounded,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.home_rounded,
                          color: AppColors.primaryColor,
                        ),
                ),
                const SizedBox(width: 16),
                // Property info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${property.viewsCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${property.inquiriesCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}