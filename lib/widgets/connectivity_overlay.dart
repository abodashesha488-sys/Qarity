import 'dart:async';

import 'package:flutter/material.dart';

import '../core/network/connectivity_manager.dart';

/// يغلّف التطبيق بالكامل ويُظهر شريطاً رفيعاً أعلى الشاشة عند انقطاع الإنترنت.
/// يعتمد على [ConnectivityManager] حتى لا تحتاج كل شاشة لتعديلها.
class ConnectivityOverlay extends StatefulWidget {
  const ConnectivityOverlay({super.key, required this.child});
  final Widget child;

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  bool _online = ConnectivityManager.instance.lastKnownOnline;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ConnectivityManager.instance.onlineStream.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _online
                ? const SizedBox(width: double.infinity, height: 0)
                : const _OfflineBanner(),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 18, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'أنت غير متصل بالإنترنت — يتم عرض البيانات المحفوظة محلياً',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
