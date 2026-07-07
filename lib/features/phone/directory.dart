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
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _filteredEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _filterEntries() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredEntries = query.isEmpty
          ? _entries
          : _entries.where((e) {
              return e.name.toLowerCase().contains(query) ||
                  e.title.toLowerCase().contains(query) ||
                  e.phone.contains(query);
            }).toList();
    });
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الهاتف'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو الرقم...',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: theme.colorScheme.primary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _filterEntries();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 1.5)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _filteredEntries.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredEntries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _buildContactCard(theme, _filteredEntries[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.phone_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('لا توجد جهات اتصال', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildContactCard(ThemeData theme, PhoneDirectoryEntry entry) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              entry.name.isNotEmpty ? entry.name[0] : '',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800),
            ),
          ),
          title: Text(entry.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          subtitle: Text(entry.title, style: theme.textTheme.bodySmall),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filled(
                onPressed: () => _makeCall(entry.phone),
                icon: const Icon(Icons.call_rounded, size: 18),
                style: IconButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.15)),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(theme, 'الهاتف:', entry.phone),
                  if (entry.secondaryPhone != null && entry.secondaryPhone!.isNotEmpty)
                    _buildInfoRow(theme, 'هاتف إضافي:', entry.secondaryPhone!),
                  if (entry.job != null && entry.job!.isNotEmpty)
                    _buildInfoRow(theme, 'الوظيفة:', entry.job!),
                  if (entry.address != null && entry.address!.isNotEmpty)
                    _buildInfoRow(theme, 'العنوان:', entry.address!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
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
