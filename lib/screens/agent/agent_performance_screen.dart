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
    return RefreshIndicator(
      onRefresh: _loadPerformanceData,
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
                  'Performance Overview',
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
                    _loadPerformanceData();
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
                  _buildStatCard('Total Properties', '${_stats['total_properties']}', Icons.home_work_rounded, AppColors.primaryColor),
                  _buildStatCard('Active Listings', '${_stats['active_properties']}', Icons.check_circle_rounded, Colors.green),
                  _buildStatCard('Sold', '${_stats['sold_properties']}', Icons.sell_rounded, Colors.blue),
                  _buildStatCard('Rented', '${_stats['rented_properties']}', Icons.key_rounded, Colors.orange),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard('Total Views', '${_stats['total_views']}', Icons.visibility_rounded, Colors.purple),
                  _buildStatCard('Total Saves', '${_stats['total_saves']}', Icons.favorite_rounded, Colors.red),
                  _buildStatCard('Inquiries', '${_stats['total_inquiries']}', Icons.message_rounded, Colors.teal),
                  _buildStatCard(
                    'Avg. Views',
                    ((_stats['avg_views'] ?? 0) as num).toDouble().toStringAsFixed(1),
                    Icons.trending_up_rounded,
                    Colors.indigo,
                  ),
                ],
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
}