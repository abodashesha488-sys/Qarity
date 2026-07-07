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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ServiceRequest) {
      setState(() {
        _request = args;
        _isLoading = false;
      });
    } else {
      _loadRequest();
    }
  }

  Future<void> _loadRequest() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      final req = await _service.getServiceRequest(args);
      if (mounted) {
        setState(() {
          _request = req;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = _request;

    if (_isLoading || request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الخدمة')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                      Icon(Icons.circle, size: 10, color: _statusColor(request.status)),
                      const SizedBox(width: 6),
                      Text('الحالة: ${request.statusLabel}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: _statusColor(request.status))),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
