import 'package:flutter/material.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/occasion_service.dart';
import '../../widgets/common_appbar_actions.dart';

class OccasionsListScreen extends StatefulWidget {
  const OccasionsListScreen({super.key});

  @override
  State<OccasionsListScreen> createState() => _OccasionsListScreenState();
}

class _OccasionsListScreenState extends State<OccasionsListScreen> {
  final OccasionService _service = OccasionService();
  List<Occasion> _occasions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOccasions();
  }

  Future<void> _loadOccasions() async {
    try {
      final occasions = await _service.getOccasionsList();
      setState(() {
        _occasions = occasions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadOccasions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المناسبات'),
        actions: CommonAppBarActions.actions(context),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.occasionsAdd);
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _occasions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _occasions.length,
                    itemBuilder: (context, index) {
                      return _buildOccasionCard(context, _occasions[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('لا توجد مناسبات مسجلة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('سجل المناسبات فارغ حالياً', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildOccasionCard(BuildContext context, Occasion occasion) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.occasionsDetail,
            arguments: occasion,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard, size: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occasion.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      occasion.date,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      occasion.location,
                      style: const TextStyle(color: Colors.orange),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
