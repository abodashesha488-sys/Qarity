import 'package:flutter/material.dart';

import '../core/network/connectivity_manager.dart';

/// Builder يعمل أثناء الاتصال وعند انقطاعه (يعرض الكاش)، مع **تثبيت آخر محتوى
/// صالح** أثناء إعادة الاشتراك المؤقتة للـ Stream — حتى لا تُعاد بناء شجرة
/// النتائج (ومنها مربع البحث) عند كل ضغطة، وهو ما كان يفقده التركيز بعد أول حرف.
class OfflineStreamBuilder<T> extends StatefulWidget {
  const OfflineStreamBuilder({
    super.key,
    required this.stream,
    required this.onlineBuilder,
    required this.cacheBuilder,
    this.progressBuilder,
    this.errorBuilder,
    this.cacheFirst = true,
  });

  final Stream<T> stream;
  final Widget Function(BuildContext, AsyncSnapshot<T>) onlineBuilder;
  final Widget Function(BuildContext) cacheBuilder;
  final Widget Function(BuildContext)? progressBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final bool cacheFirst;

  @override
  State<OfflineStreamBuilder<T>> createState() => _OfflineStreamBuilderState<T>();
}

class _OfflineStreamBuilderState<T> extends State<OfflineStreamBuilder<T>> {
  bool _gotData = false;
  T? _lastData;

  Widget _onlineView(BuildContext context, AsyncSnapshot<T> snapshot) {
    if (snapshot.hasData && !snapshot.hasError) {
      _gotData = true;
      _lastData = snapshot.data;
      return widget.onlineBuilder(context, snapshot);
    }
    if (_gotData) {
      // لا توجد بيانات الآن (إعادة اشتراك/تحميل) لكن عندنا آخر نتيجة صالحة.
      return widget.onlineBuilder(
        context,
        AsyncSnapshot<T>.withData(ConnectionState.active, _lastData as T),
      );
    }
    if (snapshot.hasError && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, snapshot.error!, snapshot.stackTrace);
    }
    if (widget.progressBuilder != null) return widget.progressBuilder!(context);
    return widget.cacheBuilder(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.cacheFirst) {
      return StreamBuilder<T>(
        stream: widget.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError && !_gotData && widget.errorBuilder != null) {
            return widget.errorBuilder!(context, snapshot.error!, snapshot.stackTrace);
          }
          return _onlineView(context, snapshot);
        },
      );
    }
    return StreamBuilder<bool>(
      stream: ConnectivityManager.instance.onlineStream,
      builder: (context, connectivitySnapshot) {
        final isOnline =
            connectivitySnapshot.data ?? ConnectivityManager.instance.lastKnownOnline;
        if (!isOnline) {
          return widget.cacheBuilder(context);
        }
        return StreamBuilder<T>(
          stream: widget.stream,
          builder: (context, snapshot) => _onlineView(context, snapshot),
        );
      },
    );
  }
}
