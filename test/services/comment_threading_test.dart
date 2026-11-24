import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/comment_thread_helper.dart';
import 'package:qurity/models/market_extra_models.dart';

class _MockComment {
  const _MockComment(this.id, this.parentId, this.createdAt);
  final String id;
  final String? parentId;
  final DateTime createdAt;
}

void main() {
  group('CommentThreadHelper', () {
    test(
        'places a reply directly beneath its parent comment rather than at the end under another user',
        () {
      final t0 = DateTime(2026, 11, 25, 10);
      final items = [
        _MockComment('c1_userA', null, t0),
        _MockComment('c2_userB', null, t0.add(const Duration(minutes: 5))),
        // رد على التعليق الأول (c1_userA) رغم أن توقيته بعد c2_userB
        _MockComment('c3_replyToA', 'c1_userA', t0.add(const Duration(minutes: 10))),
      ];

      final ordered = CommentThreadHelper.orderThreaded<_MockComment>(
        items,
        idOf: (c) => c.id,
        parentIdOf: (c) => c.parentId,
        createdAtOf: (c) => c.createdAt,
      );

      expect(
        ordered.map((c) => c.id).toList(),
        ['c1_userA', 'c3_replyToA', 'c2_userB'],
      );
    });

    test('keeps nested reply-to-reply grouped under original root in order', () {
      final t0 = DateTime(2026, 11, 25, 10);
      final items = [
        _MockComment('root1', null, t0),
        _MockComment('root2', null, t0.add(const Duration(minutes: 2))),
        _MockComment('r1', 'root1', t0.add(const Duration(minutes: 3))),
        _MockComment('r2_nested', 'r1', t0.add(const Duration(minutes: 4))),
      ];

      final ordered = CommentThreadHelper.orderThreaded<_MockComment>(
        items,
        idOf: (c) => c.id,
        parentIdOf: (c) => c.parentId,
        createdAtOf: (c) => c.createdAt,
      );

      expect(
        ordered.map((c) => c.id).toList(),
        ['root1', 'r1', 'r2_nested', 'root2'],
      );
    });

    test('handles orphan replies and cyclic parentIds safely', () {
      final t0 = DateTime(2026, 11, 25, 10);
      final items = [
        _MockComment('orphan', 'deleted_parent', t0),
        _MockComment('cycA', 'cycB', t0.add(const Duration(minutes: 1))),
        _MockComment('cycB', 'cycA', t0.add(const Duration(minutes: 2))),
      ];

      final ordered = CommentThreadHelper.orderThreaded<_MockComment>(
        items,
        idOf: (c) => c.id,
        parentIdOf: (c) => c.parentId,
        createdAtOf: (c) => c.createdAt,
      );

      expect(ordered.length, 3);
      expect(ordered.first.id, 'orphan');
    });
  });

  test('BuyRequestComment preserves reply threading and like fields', () {
    final comment = BuyRequestComment(
      id: 'bc1',
      requestId: 'req1',
      userId: 'u1',
      userName: 'أحمد',
      text: 'متاح عندي إن شاء الله',
      parentId: 'bc0',
      replyToUser: 'محمود',
      likes: 2,
      likedBy: const ['u2', 'u3'],
      createdAt: DateTime(2026, 11, 25, 12),
    );

    final json = comment.toJson();
    final restored = BuyRequestComment.fromJson(json, 'bc1', 'req1');

    expect(restored.parentId, 'bc0');
    expect(restored.replyToUser, 'محمود');
    expect(restored.likes, 2);
    expect(restored.likedBy, ['u2', 'u3']);
  });
}
