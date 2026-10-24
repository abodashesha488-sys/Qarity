import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/relative_time.dart';
import '../models/legal_models.dart' show ConsultationReply;

/// عارض صور الاستشارة المصغّرة مع إمكانية التكبير عند النقر.
class ConsultationImageGallery extends StatelessWidget {
  const ConsultationImageGallery({
    super.key,
    required this.images,
    this.thumbHeight = 72,
  });

  final List<String> images;
  final double thumbHeight;

  void _openFullPreview(BuildContext context, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (_, index) => InteractiveViewer(
                maxScale: 3.5,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.white60, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: thumbHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _openFullPreview(context, i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: images[i],
              width: thumbHeight,
              height: thumbHeight,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: thumbHeight,
                height: thumbHeight,
                color: Colors.grey.withValues(alpha: 0.15),
              ),
              errorWidget: (_, __, ___) => Container(
                width: thumbHeight,
                height: thumbHeight,
                color: Colors.grey.withValues(alpha: 0.15),
                child: const Icon(Icons.broken_image_rounded, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// شريط ومحادثة الردود والتعقيبات المتبادلة بين السائل والمستشار.
class ConsultationRepliesThread extends StatefulWidget {
  const ConsultationRepliesThread({
    super.key,
    required this.consultationId,
    required this.ownerId,
    required this.currentUserId,
    required this.repliesStream,
    required this.onSendReply,
    required this.primaryColor,
    required this.isAdvisor,
    this.advisorTitle = 'المستشار',
  });

  final String consultationId;
  final String ownerId;
  final String currentUserId;
  final Stream<List<ConsultationReply>> repliesStream;
  final Future<void> Function(String text) onSendReply;
  final Color primaryColor;
  final bool isAdvisor;
  final String advisorTitle;

  @override
  State<ConsultationRepliesThread> createState() =>
      _ConsultationRepliesThreadState();
}

class _ConsultationRepliesThreadState extends State<ConsultationRepliesThread> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  bool get _canParticipate =>
      widget.currentUserId.isNotEmpty &&
      (widget.currentUserId == widget.ownerId || widget.isAdvisor);

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await widget.onSendReply(text);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إرسال الرد: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.forum_outlined, size: 16, color: widget.primaryColor),
            const SizedBox(width: 6),
            Text(
              'الردود والتعقيبات الإضافية',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: widget.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<ConsultationReply>>(
          stream: widget.repliesStream,
          builder: (context, snapshot) {
            final replies = snapshot.data ?? [];
            if (replies.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'لا توجد تعقيبات إضافية بعد. يمكن لصاحب الاستشارة أو المستشار إضافة تعقيبات أدناه.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: replies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = replies[i];
                final isAdv = r.isAdvisor;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdv
                        ? widget.primaryColor.withValues(alpha: 0.08)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAdv
                          ? widget.primaryColor.withValues(alpha: 0.25)
                          : theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAdv
                                ? Icons.verified_rounded
                                : Icons.person_outline_rounded,
                            size: 14,
                            color: isAdv
                                ? widget.primaryColor
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAdv
                                ? (r.advisorTitle.isNotEmpty
                                    ? r.advisorTitle
                                    : 'المستشار')
                                : (r.authorName.isNotEmpty
                                    ? 'صاحب الاستشارة (${r.authorName})'
                                    : 'صاحب الاستشارة'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isAdv
                                  ? widget.primaryColor
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            relativeTimeLabelAr(r.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.text,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        if (_canParticipate) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: widget.isAdvisor
                        ? 'أضف تعقيباً أو توجيهاً إضافياً...'
                        : 'أضف رداً أو استفساراً توضيحياً للمستشار...',
                    hintStyle: const TextStyle(fontSize: 12),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _submit,
                style: IconButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ] else if (widget.currentUserId.isEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'سجّل الدخول للمشاركة وإضافة تعقيب على هذه الاستشارة.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
