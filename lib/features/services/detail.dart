import 'package:flutter/material.dart';

import '../../models/data_models.dart';
import '../../services/service_request_service.dart';
import '../../widgets/common_appbar_actions.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final ServiceRequestService _service = ServiceRequestService();
  ServiceRequest? _request;
  bool _isLoading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ServiceRequest) {
      setState(() {
        _request = args;
        _isLoading = false;
      });
    } else if (args is String) {
      _loadRequest(args);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRequest(String id) async {
    try {
      final req = await _service.getServiceRequest(id);
      if (mounted) {
        setState(() {
          _request = req;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = _request;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الخدمة'),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: theme.colorScheme.surface,
          actions: CommonAppBarActions.actions(context),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (request == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الخدمة'),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: theme.colorScheme.surface,
          actions: CommonAppBarActions.actions(context),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.request_page_rounded, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('لم يتم العثور على الطلب', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('رجوع'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(request.type, style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        child: Icon(Icons.request_page_rounded, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(request.type, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(request.userName, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(icon: Icons.description_rounded, label: 'الوصف', value: request.description),
                  _DetailRow(icon: Icons.location_on_rounded, label: 'الموقع', value: request.location),
                  _DetailRow(icon: Icons.access_time_rounded, label: 'تاريخ الطلب', value: '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}'),
                  if (request.assignedTo != null) _DetailRow(icon: Icons.person_rounded, label: 'مسند إلى', value: request.assignedTo!),
                  if (request.notes != null) _DetailRow(icon: Icons.notes_rounded, label: 'ملاحظات', value: request.notes!),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: request.statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: request.statusColor),
                            const SizedBox(width: 6),
                            Text('الحالة: ${request.statusLabel}',
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: request.statusColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
