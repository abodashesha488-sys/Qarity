part of 'market_tabs_screen.dart';

// ═══════════════════ Tab 3: سلع مطلوبة ═══════════════════
class _BuyRequestsTab extends StatefulWidget {
  const _BuyRequestsTab();

  @override
  State<_BuyRequestsTab> createState() => _BuyRequestsTabState();
}

class _BuyRequestsTabState extends State<_BuyRequestsTab> {
  final BuyRequestService _service = BuyRequestService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return OfflineStreamBuilder<List<BuyRequest>>(
      stream: _service.getOpenRequestsStream(),
      onlineBuilder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _TabEmpty(
            icon: Icons.request_quote_rounded,
            message: 'لا توجد سلع مطلوبة حالياً',
          );
        }
        return _buildBuyRequestsList(theme, uid, items);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getBuyRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = (snapshot.data ?? []).map((j) => BuyRequest.fromJson(j, 'cache')).toList();
          if (items.isEmpty) {
            return const _TabEmpty(icon: Icons.request_quote_rounded, message: 'لا توجد طلبات مخزنة');
          }
          return _buildBuyRequestsList(theme, uid, items);
        },
      ),
    );
  }

  Widget _buildBuyRequestsList(ThemeData theme, String? uid, List<BuyRequest> items) {
    return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final r = items[i];
            final mine = uid != null && r.userId == uid;
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  if (r.imageUrl.isNotEmpty)
                    SizedBox(
                        width: 90, height: 90, child: _net(r.imageUrl, theme)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(r.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15))),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                    color:
                                        r.statusColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(r.statusLabel,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: r.statusColor)),
                              ),
                            ],
                          ),
                          if (r.details.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(r.details,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.4)),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(r.userName,
                                  style: const TextStyle(fontSize: 12)),
                              if (r.budget.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.payments_rounded,
                                    size: 14, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(r.budget,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ],
                              const Spacer(),
                              if (mine)
                                TextButton.icon(
                                  onPressed: () async {
                                    await _service.close(r.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('تم إغلاق الطلب')));
                                    }
                                  },
                                  icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 16),
                                  label: const Text('تمت التلبية'),
                                  style: TextButton.styleFrom(
                                      foregroundColor:
                                          theme.colorScheme.primary),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
             ).animate(delay: (i * 40).ms).fadeIn();
          },
        );
  }
}

// ═══════════════════ Tab 4: تبرعات ═══════════════════
class _DonationsTab extends StatefulWidget {
  const _DonationsTab();

  @override
  State<_DonationsTab> createState() => _DonationsTabState();
}

class _DonationsTabState extends State<_DonationsTab> {
  final DonationService _service = DonationService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return OfflineStreamBuilder<List<Donation>>(
      stream: _service.getAvailableDonationsStream(),
      onlineBuilder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _TabEmpty(
            icon: Icons.volunteer_activism_rounded,
            message: 'لا توجد تبرعات حالياً',
          );
        }
        return _buildDonationsList(theme, uid, items);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getDonations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = (snapshot.data ?? []).map((j) => Donation.fromJson(j, 'cache')).toList();
          if (items.isEmpty) {
            return const _TabEmpty(icon: Icons.volunteer_activism_rounded, message: 'لا توجد تبرعات مخزنة');
          }
          return _buildDonationsList(theme, uid, items);
        },
      ),
    );
  }

  Widget _buildDonationsList(ThemeData theme, String? uid, List<Donation> items) {
    return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final d = items[i];
            final mine = uid != null && d.userId == uid;
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  SizedBox(
                      width: 96, height: 96, child: _net(d.imageUrl, theme)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text('تبرع • ${d.category}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w700)),
                          if (d.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(d.description,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 13,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(d.userName,
                                  style: const TextStyle(fontSize: 11)),
                              if (d.imageUrls.length > 1)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.collections_rounded,
                                          size: 12, color: Colors.grey),
                                      const SizedBox(width: 2),
                                      Text('${d.imageUrls.length}',
                                          style: const TextStyle(fontSize: 11)),
                                    ],
                                  ),
                                ),
                              const Spacer(),
                              if (mine)
                                TextButton.icon(
                                  onPressed: () async {
                                    await _service.markDonated(d.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'تم تحديد السلعة كـ "تم التبرع"')));
                                    }
                                  },
                                  icon: const Icon(Icons.done_all_rounded,
                                      size: 16),
                                  label: const Text('تم التبرع'),
                                  style: TextButton.styleFrom(
                                      foregroundColor:
                                          theme.colorScheme.primary),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
             ).animate(delay: (i * 40).ms).fadeIn();
          },
        );
  }
}

class _TabEmpty extends StatelessWidget {
  const _TabEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
