import 'package:flutter/material.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/obituary_service.dart';
import '../../widgets/common_appbar_actions.dart';

class ObituariesListScreen extends StatefulWidget {
  const ObituariesListScreen({super.key});

  @override
  State<ObituariesListScreen> createState() => _ObituariesListScreenState();
}

class _ObituariesListScreenState extends State<ObituariesListScreen> {
  final ObituaryService _service = ObituaryService();
  List<Obituary> _obituaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadObituaries();
  }

  Future<void> _loadObituaries() async {
    try {
      final obituaries = await _service.getObituariesList();
      setState(() {
        _obituaries = obituaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadObituaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل العزاء'),
        actions: CommonAppBarActions.actions(context),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _obituaries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _obituaries.length,
                    itemBuilder: (context, index) {
                      return _buildObituaryCard(context, _obituaries[index]);
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
          Icon(Icons.grade, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('لا توجد تعازي مسجلة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('سجل العزاء فارغ حالياً', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildObituaryCard(BuildContext context, Obituary obituary) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.obituariesDetail,
            arguments: obituary,
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
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      obituary.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'عمر: ${obituary.age}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'توفي: ${obituary.date}',
                      style: const TextStyle(color: Colors.red),
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
