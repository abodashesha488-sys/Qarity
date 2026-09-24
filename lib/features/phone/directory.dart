import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../services/phone_directory_service.dart';
import '../../widgets/qurity_app_bar.dart';

class PhoneDirectoryScreen extends StatefulWidget {
  const PhoneDirectoryScreen({super.key, this.embedded = false});

  /// عند التضمين داخل تبويب (دليل الخدمات) يُخفى الـAppBar الخاص بالشاشة
  /// مع الإبقاء على كامل التصميم والبرمجة كما هي.
  final bool embedded;

  @override
  State<PhoneDirectoryScreen> createState() => _PhoneDirectoryScreenState();
}

class _PhoneDirectoryScreenState extends State<PhoneDirectoryScreen> {
  final PhoneDirectoryService _service = PhoneDirectoryService();
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<PhoneDirectoryEntry> _entries = [];
  List<PhoneDirectoryEntry> _filteredEntries = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _checkAdminStatus();
    _searchController.addListener(_filterEntries);
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isAdmin = await _adminService.isAdminUser(user.uid);
      if (!mounted) return;
      setState(() => _isAdmin = isAdmin);
      if (isAdmin) {
        _loadPendingCount();
      }
    }
  }

  Future<void> _loadPendingCount() async {
    try {
      final count = await _adminService.getPendingCountFuture('phone_directory');
      if (!mounted) return;
      setState(() => _pendingCount = count);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingCount = 0);
    }
  }

  Future<void> _loadEntries() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final entries = await _service.getVisibleEntriesList(uid);
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
              return _normalizePhone(e.name).contains(query) ||
                  _normalizePhone(e.title).contains(query) ||
                  _normalizePhone(e.phone).contains(query) ||
                  (e.secondaryPhone != null &&
                      _normalizePhone(e.secondaryPhone!).contains(query));
            }).toList();
    });
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\+\(\)\.]+'), '');
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
      backgroundColor: widget.embedded ? Colors.transparent : null,
      appBar: widget.embedded
          ? null
          : QurityAppBar(
              title: 'دليل الهاتف',
              color: const Color(0xFF37474F),
              actions: _isAdmin
                  ? [
                      IconButton(
                        icon: Icon(_pendingCount > 0 ? Icons.pending_rounded : Icons.check_rounded,
                            color: _pendingCount > 0 ? Colors.orange : Colors.white),
                        tooltip: 'طلبات قيد المراجعة',
                        onPressed: _pendingCount > 0
                            ? () => _showPendingBottomSheet()
                            : null,
                      ),
                    ]
                  : const [],
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _navigateToAddScreen(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة جهة اتصال'),
                tooltip: 'إضافة جهة اتصال جديدة',
                backgroundColor: theme.colorScheme.primary,
              ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('لا توجد جهات اتصال', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('يمكنك إضافتها من القائمة العلوية', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildContactCard(ThemeData theme, PhoneDirectoryEntry entry) {
    final isApproved = entry.isApproved;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isApproved
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
              : theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: GestureDetector(
            onTap: () => _showContactDetailDialog(entry),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              foregroundImage: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(entry.photoUrl!)
                  : null,
              child: Text(
                (entry.photoUrl != null && entry.photoUrl!.isNotEmpty) ? '' : (entry.name.isNotEmpty ? entry.name[0] : ''),
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          title: Text(entry.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          subtitle: isApproved
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_rounded, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'قيد المراجعة',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filled(
                onPressed: () => _makeCall(entry.phone),
                icon: const Icon(Icons.call_rounded, size: 18),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF6F4E37).withValues(alpha: 0.15)),
              ),
              if (_isAdmin && !isApproved)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  onSelected: (String value) {
                    if (value == 'approve') {
                      _approveEntry(entry);
                    } else if (value == 'reject') {
                      _rejectEntry(entry);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                    const PopupMenuItem<String>(
                      value: 'approve',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF6F4E37)),
                          SizedBox(width: 8),
                          Text('موافقة'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'reject',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('رفض'),
                        ],
                      ),
                    ),
                  ],
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

  Future<void> _approveEntry(PhoneDirectoryEntry entry) async {
    if (!mounted) return;
    setState(() {});
    try {
      await _adminService.approveItem('phone_directory', entry.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول الدخول في الدليل'), backgroundColor: Color(0xFF6F4E37)),
      );
      _loadEntries();
      _loadPendingCount();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectEntry(PhoneDirectoryEntry entry) async {
    if (!mounted) return;
    setState(() {});
    try {
      await _adminService.rejectItem('phone_directory', entry.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض الدخول'), backgroundColor: Colors.red),
      );
      _loadEntries();
      _loadPendingCount();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showContactDetailDialog(PhoneDirectoryEntry entry) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // صورة كبيرة
              CircleAvatar(
                radius: 64,
                backgroundColor: const Color(0xFF6F4E37).withValues(alpha: 0.1),
                foregroundImage: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(entry.photoUrl!)
                    : null,
                child: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                    ? null
                    : Text(
                        entry.name.isNotEmpty ? entry.name[0] : '',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Color(0xFF6F4E37)),
                      ),
              ),
              const SizedBox(height: 16),
              // الاسم
              Text(entry.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              if (entry.job != null && entry.job!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(entry.job!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
              const SizedBox(height: 16),
              // أزرار الهاتف والواتساب
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: () => _makeCall(entry.phone),
                    icon: const Icon(Icons.call_rounded),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF6F4E37).withValues(alpha: 0.15)),
                  ),
                  const SizedBox(width: 12),
                  FutureBuilder<String?>(
                    future: _getWhatsAppUrl(entry.phone),
                    builder: (ctx, snap) {
                      final url = snap.data;
                      return IconButton.filled(
                        onPressed: url != null ? () => _launchUrl(url) : null,
                        icon: const Icon(Icons.message_rounded),
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // رقم الهاتف
              Text(entry.phone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              if (entry.secondaryPhone != null && entry.secondaryPhone!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(entry.secondaryPhone!, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
              if (entry.address != null && entry.address!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(entry.address!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey))),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _getWhatsAppUrl(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[\s\-\+\(\)\.]+'), '');
    final waPhone = normalized.startsWith('0') ? '20${normalized.substring(1)}' : normalized;
    final uri = Uri.parse('https://wa.me/$waPhone');
    if (await canLaunchUrl(uri)) return uri.toString();
    return null;
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _navigateToAddScreen() {
    Navigator.pushNamed(context, AppRoutes.phoneDirectoryAdd).then((_) {
      _refresh();
    });
  }

  void _showPendingBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _PendingEntriesBottomSheet(
        onApprove: _approveEntry,
        onReject: _rejectEntry,
        pendingCount: _pendingCount,
      ),
    );
  }
}

class _PendingEntriesBottomSheet extends StatefulWidget {
  final Function(PhoneDirectoryEntry) onApprove;
  final Function(PhoneDirectoryEntry) onReject;
  final int pendingCount;
  const _PendingEntriesBottomSheet({
    required this.onApprove,
    required this.onReject,
    required this.pendingCount,
  });

  @override
  State<_PendingEntriesBottomSheet> createState() => _PendingEntriesBottomSheetState();
}

class _PendingEntriesBottomSheetState extends State<_PendingEntriesBottomSheet> {
  final _searchController = TextEditingController();
  List<PhoneDirectoryEntry> _pendingEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingEntries();
    _searchController.addListener(_filterPending);
  }

  Future<void> _loadPendingEntries() async {
    final service = PhoneDirectoryService();
    try {
      final snapshot = await service.getEntriesList();
      setState(() {
        _pendingEntries = snapshot.where((e) => e.isApproved == false).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPending() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _pendingEntries = query.isEmpty
          ? _pendingEntries
          : _pendingEntries.where((e) {
              return e.name.toLowerCase().contains(query) ||
                  e.phone.contains(query);
            }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPending);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('طلباتpending (${widget.pendingCount})', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'ابحث بالاسم أو الرقم...',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _filterPending(),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pendingEntries.isEmpty
                  ? const Center(child: Text('لا توجد طلبات pending'))
                  : Expanded(
                      child: ListView.separated(
                        itemCount: _pendingEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _PendingEntryCard(
                          entry: _pendingEntries[index],
                          onApprove: widget.onApprove,
                          onReject: widget.onReject,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}

class _PendingEntryCard extends StatefulWidget {
  final PhoneDirectoryEntry entry;
  final Function(PhoneDirectoryEntry) onApprove;
  final Function(PhoneDirectoryEntry) onReject;

  const _PendingEntryCard({
    required this.entry,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_PendingEntryCard> createState() => _PendingEntryCardState();
}

class _PendingEntryCardState extends State<_PendingEntryCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  foregroundImage: widget.entry.photoUrl != null && widget.entry.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(widget.entry.photoUrl!)
                      : null,
                  child: Text(
                    (widget.entry.photoUrl != null && widget.entry.photoUrl!.isNotEmpty) ? '' : (widget.entry.name.isNotEmpty ? widget.entry.name[0] : ''),
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.entry.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      Text(widget.entry.phone, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  onSelected: (String value) {
                    if (value == 'approve') {
                      widget.onApprove(widget.entry);
                    } else if (value == 'reject') {
                      widget.onReject(widget.entry);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                    const PopupMenuItem<String>(
                      value: 'approve',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF6F4E37)),
                          SizedBox(width: 8),
                          Text('موافقة'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'reject',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('رفض'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(theme, 'الهاتف:', widget.entry.phone),
            if (widget.entry.secondaryPhone != null && widget.entry.secondaryPhone!.isNotEmpty)
              _buildInfoRow(theme, 'هاتف إضافي:', widget.entry.secondaryPhone!),
            if (widget.entry.job != null && widget.entry.job!.isNotEmpty)
              _buildInfoRow(theme, 'الوظيفة:', widget.entry.job!),
            if (widget.entry.address != null && widget.entry.address!.isNotEmpty)
              _buildInfoRow(theme, 'العنوان:', widget.entry.address!),
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
}