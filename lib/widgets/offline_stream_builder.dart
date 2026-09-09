import 'package:flutter/material.dart';

import '../core/network/connectivity_manager.dart';

class OfflineStreamBuilder<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (cacheFirst) {
      return StreamBuilder<bool>(
        stream: ConnectivityManager.instance.onlineStream,
        builder: (context, connectivitySnapshot) {
          final isOnline = connectivitySnapshot.data ?? ConnectivityManager.instance.lastKnownOnline;

          if (!isOnline) {
            return cacheBuilder(context);
          }

          return StreamBuilder<T>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasData && !snapshot.hasError) {
                return onlineBuilder(context, snapshot);
              }
              if (snapshot.hasError && !snapshot.hasData) {
                if (errorBuilder != null) return errorBuilder!(context, snapshot.error!, snapshot.stackTrace);
                return cacheBuilder(context);
              }
              if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                if (progressBuilder != null) return progressBuilder!(context);
                return cacheBuilder(context);
              }
              return onlineBuilder(context, snapshot);
            },
          );
        },
      );
    }

    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasData && !snapshot.hasError) {
          return onlineBuilder(context, snapshot);
        }
        if (snapshot.hasError && !snapshot.hasData) {
          if (errorBuilder != null) return errorBuilder!(context, snapshot.error!, snapshot.stackTrace);
          return cacheBuilder(context);
        }
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          if (progressBuilder != null) return progressBuilder!(context);
          return cacheBuilder(context);
        }
        return onlineBuilder(context, snapshot);
      },
    );
  }
}
