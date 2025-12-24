import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';
import 'package:wenest/services/supabase_service.dart';
import 'package:wenest/models/agency.dart';
import 'package:wenest/models/property.dart';

// ============ ANALYTICS SCREEN ============

class AnalyticsScreen extends StatefulWidget {
  final Agency agency;

  const AnalyticsScreen({super.key, required this.agency});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _supabaseService = SupabaseService();
  
  Map<String, dynamic> _stats = {};
  List<Property> _topProperties = [];
  bool _isLoading = true;
  String _selectedPeriod = '30';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _supabaseService.getAgencyStats(widget.agency.id);
      final topProps = await _supabaseService.getTopPerformingProperties(
        widget.agency.id,
        limit: 5,
        sortBy: 'views',
      );

      setState(() {
        _stats = stats;
        _topProperties = topProps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: AppColors.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analytics Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: const [
                    DropdownMenuItem(value: '7', child: Text('Last 7 days')),
                    DropdownMenuItem(value: '30', child: Text('Last 30 days')),
                    DropdownMenuItem(value: '90', child: Text('Last 90 days')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedPeriod = value!);
                    _loadAnalytics();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Stats Grid
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard(
                    'Total Properties',
                    _stats['total_properties']?.toString() ?? '0',
                    Icons.home_work_rounded,
                    AppColors.primaryColor,
                  ),
                  _buildStatCard(
                    'Active Listings',
                    _stats['active_properties']?.toString() ?? '0',
                    Icons.check_circle_rounded,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Total Views',
                    _stats['total_views']?.toString() ?? '0',
                    Icons.visibility_rounded,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Total Inquiries',
                    _stats['total_inquiries']?.toString() ?? '0',
                    Icons.message_rounded,
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Average Performance
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor.withValues(alpha: 0.1), AppColors.lightTeal.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Average Performance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildAvgStat(
                      'Views per Property',
                      (_stats['average_views_per_property'] ?? 0.0).toStringAsFixed(1),
                      Icons.trending_up_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Top Performing Properties
              const Text(
                'Top Performing Properties',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              if (_topProperties.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No data available', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topProperties.length,
                  itemBuilder: (context, index) {
                    final property = _topProperties[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          property.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${property.viewsCount} views • ${property.inquiriesCount} inquiries'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.pushNamed(context, '/property_detail', arguments: property.id);
                        },
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvgStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }
}