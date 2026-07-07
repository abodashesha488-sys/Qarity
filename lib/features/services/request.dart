import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/service_request_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with SingleTickerProviderStateMixin {
  final ServiceRequestService _requestService = ServiceRequestService();
  final UserService _userService = UserService();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isSubmitting = false;
  List<ServiceRequest> _myRequests = [];
  bool _isLoadingRequests = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _typeController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadMyRequests() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final requests = await _requestService.getServiceRequestsList(userId: user.uid);
    if (!mounted) return;
    setState(() {
      _myRequests = requests;
      _isLoadingRequests = false;
    });
  }

  Future<void> _submitRequest() async {
    final type = _typeController.text.trim();
    final desc = _descController.text.trim();
    final location = _locationController.text.trim();

    if (type.isEmpty || desc.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول'), backgroundColor: Colors.orange),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final userModel = await _userService.getUser(user.uid);
      final request = ServiceRequest(
        id: '',
        userId: user.uid,
        userName: userModel?.name ?? user.displayName ?? 'مستخدم',
        type: type,
        description: desc,
        location: location,
        createdAt: DateTime.now(),
      );

      await _requestService.createServiceRequest(request);

      if (!mounted) return;
      _typeController.clear();
      _descController.clear();
      _locationController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب بنجاح'), backgroundColor: Colors.green),
      );

      _tabController.animateTo(1);
      await _loadMyRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الطلب: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلب الخدمة'),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: theme.colorScheme.surface,
          actions: CommonAppBarActions.actions(context),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'طلب جديد'),
              Tab(text: 'طلباتي'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _RequestTab(
              typeController: _typeController,
              descController: _descController,
              locationController: _locationController,
              isSubmitting: _isSubmitting,
              onSubmit: _submitRequest,
            ),
            _MyRequestsTab(requests: _myRequests, isLoading: _isLoadingRequests),
          ],
        ),
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  final TextEditingController typeController;
  final TextEditingController descController;
  final TextEditingController locationController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _RequestTab({
    required this.typeController,
    required this.descController,
    required this.locationController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            controller: typeController,
            decoration: InputDecoration(
              labelText: 'نوع الطلب',
              prefixIcon: Icon(Icons.category_rounded, color: theme.colorScheme.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'وصف الطلب',
              prefixIcon: const Icon(Icons.description_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: locationController,
            decoration: InputDecoration(
              labelText: 'الموقع',
              prefixIcon: Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('إرسال الطلب', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRequestsTab extends StatelessWidget {
  final List<ServiceRequest> requests;
  final bool isLoading;

  const _MyRequestsTab({required this.requests, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('لا توجد طلبات بعد', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = requests[index];
        Color statusColor;
        switch (req.status) {
          case 'pending':
            statusColor = Colors.orange;
          case 'in_progress':
            statusColor = Colors.blue;
          case 'completed':
            statusColor = Colors.green;
          case 'cancelled':
            statusColor = Colors.red;
          default:
            statusColor = Colors.grey;
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(Icons.request_page_rounded, color: statusColor),
            ),
            title: Text(req.type, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(req.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(req.statusLabel, style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Text(req.location, style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.serviceDetail, arguments: req),
          ),
        );
      },
    );
  }
}
