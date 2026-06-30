import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/data_models.dart';
import '../../services/phone_directory_service.dart';
import '../../widgets/common_appbar_actions.dart';

class PhoneDirectoryScreen extends StatefulWidget {
  const PhoneDirectoryScreen({super.key});

  @override
  State<PhoneDirectoryScreen> createState() => _PhoneDirectoryScreenState();
}

class _PhoneDirectoryScreenState extends State<PhoneDirectoryScreen> {
  final PhoneDirectoryService _service = PhoneDirectoryService();
  final TextEditingController _searchController = TextEditingController();
  List<PhoneDirectoryEntry> _entries = [];
  List<PhoneDirectoryEntry> _filteredEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _searchController.addListener(_filterEntries);
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await _service.getEntriesList();
      setState(() {
        _entries = entries;
        _filteredEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterEntries() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredEntries = _entries);
    } else {
      setState(() {
        _filteredEntries = _entries.where((e) {
          return e.name.toLowerCase().contains(query) ||
              e.title.toLowerCase().contains(query) ||
              e.phone.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadEntries();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterEntries);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الهاتف'),
        actions: CommonAppBarActions.actions(context),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الرقم...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 1.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredEntries.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredEntries.length,
                          itemBuilder: (context, index) {
                            return _buildContactCard(context, _filteredEntries[index]);
                          },
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
          Icon(Icons.phone, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('لا توجد جهات اتصال', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('دليل الهاتف فارغ حالياً', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, PhoneDirectoryEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            entry.name.isNotEmpty ? entry.name[0] : '',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(entry.name),
        subtitle: Text(entry.title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () => _makeCall(entry.phone),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('الهاتف:', entry.phone),
                if (entry.secondaryPhone != null && entry.secondaryPhone!.isNotEmpty)
                  _buildInfoRow('هاتف إضافي:', entry.secondaryPhone!),
                if (entry.job != null && entry.job!.isNotEmpty)
                  _buildInfoRow('الوظيفة:', entry.job!),
                if (entry.address != null && entry.address!.isNotEmpty)
                  _buildInfoRow('العنوان:', entry.address!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
