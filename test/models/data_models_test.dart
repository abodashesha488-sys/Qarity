import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/data_models.dart';

void main() {
  final now = DateTime(2020);

  group('NewsItem', () {
    final json = <String, dynamic>{
      'title': 'عنوان',
      'subtitle': 'موضوع',
      'imageUrl': 'https://x/y.jpg',
      'imageUrls': ['a', 'b'],
      'date': '2020-01-01',
      'views': 5,
      'likes': 3,
      'comments': 2,
      'category': 'عام',
      'isApproved': true,
      'authorId': 'au',
      'authorName': 'كاتب',
      'createdAt': Timestamp.fromDate(now),
    };

    test('fromJson maps all fields', () {
      final m = NewsItem.fromJson(json, 'id1');
      expect(m.id, 'id1');
      expect(m.title, 'عنوان');
      expect(m.imageUrls, ['a', 'b']);
      expect(m.likes, 3);
      expect(m.createdAt, now);
    });

    test('toJson round-trips scalars', () {
      final m = NewsItem.fromJson(json, 'id1');
      final out = m.toJson();
      expect(out['title'], 'عنوان');
      expect(out['likes'], 3);
      expect(out['isApproved'], isTrue);
      expect(out['category'], 'عام');
    });

    test('missing fields fall back to defaults', () {
      final m = NewsItem.fromJson(<String, dynamic>{}, 'id2');
      expect(m.title, '');
      expect(m.likes, 0);
      expect(m.isApproved, isFalse);
    });
  });

  group('MarketProduct', () {
    test('discount math when on offer', () {
      const p = MarketProduct(
        id: 'p1',
        name: 'سلعة',
        description: 'وصف',
        price: 100,
        imageUrl: '',
        category: 'عام',
        sellerName: 'بائع',
        sellerPhone: '123',
        isOnOffer: true,
        offerPrice: 80,
      );
      expect(p.effectivePrice, 80);
      expect(p.discountPercent, 20);
      expect(p.isInStock, isFalse); // stock 0
    });

    test('no discount when not on offer', () {      const p = MarketProduct(
        id: 'p2',
        name: 'سلعة',
        description: 'وصف',
        price: 100,
        imageUrl: '',
        category: 'عام',
        sellerName: 'بائع',
        sellerPhone: '123',
        stock: 5,
      );
      expect(p.effectivePrice, 100);
      expect(p.discountPercent, 0);
      expect(p.isInStock, isTrue);
    });

    test('عرض غير مخفّض فعليًا لا يُغيّر السعر ولا النسبة', () {
      MarketProduct offer({required double price, required double? offerPrice}) =>
          MarketProduct(
            id: 'p',
            name: 'سلعة',
            description: 'وصف',
            price: price,
            imageUrl: '',
            category: 'عام',
            sellerName: 'بائع',
            sellerPhone: '123',
            isOnOffer: true,
            offerPrice: offerPrice,
          );

      // سعر العرض أعلى من الأصلي (خطأ إدخال) ⇒ يُتجاهل بدل سعر أعلى + خصم سالب
      final higher = offer(price: 100, offerPrice: 120);
      expect(higher.hasActiveOffer, isFalse);
      expect(higher.effectivePrice, 100);
      expect(higher.discountPercent, 0);

      // سعر العرض يساوي الأصلي ⇒ لا عرض
      final equal = offer(price: 100, offerPrice: 100);
      expect(equal.hasActiveOffer, isFalse);
      expect(equal.discountPercent, 0);

      // السعر صفر ⇒ لا قسمة على صفر
      final zero = offer(price: 0, offerPrice: 0);
      expect(zero.discountPercent, 0);
      expect(zero.effectivePrice, 0);
      expect(zero.discountPercent.isNaN, isFalse);

      // العرض السليم ما زال يعمل
      final good = offer(price: 100, offerPrice: 80);
      expect(good.hasActiveOffer, isTrue);
      expect(good.effectivePrice, 80);
      expect(good.discountPercent, 20);
    });

    test('سلّم صور البائعين يتصاعد مع ترتيب الفئات', () {
      final limits = SellerType.values.map((t) => t.maxImages).toList();
      final sorted = [...limits]..sort();
      expect(limits, sorted, reason: 'ترتيب الفئات يجب أن يساوي ترتيب الحدود');
      expect(limits, [1, 3, 5, 10]);
      expect(SellerType.premiumSeller.maxImages,
          greaterThan(SellerType.goldSeller.maxImages));
    });

    test('copyWithApproved preserves fields', () {
      const p = MarketProduct(
        id: 'p3',
        name: 'سلعة',
        description: 'وصف',
        price: 50,
        imageUrl: '',
        category: 'عام',
        sellerName: 'بائع',
        sellerPhone: '123',
      );
      final approved = p.copyWithApproved(isApproved: true);
      expect(approved.isApproved, isTrue);
      expect(approved.name, 'سلعة');
      expect(approved.price, 50);
    });
  });

  group('ServiceRequest', () {
    test('status label and color resolve', () {
      final req = ServiceRequest(
        id: 's1',
        userId: 'u',
        userName: 'مستخدم',
        type: 'كهرباء',
        description: 'وصف',
        location: 'مكان',
        createdAt: DateTime(2020),
      );
      expect(req.statusLabel, 'قيد الانتظار'); // pending default
      expect(req.statusColor, const Color(0xFFFF9800));

      final inProgress = ServiceRequest(
        id: 's2',
        userId: 'u',
        userName: 'مستخدم',
        type: 'كهرباء',
        description: 'وصف',
        location: 'مكان',
        status: 'in_progress',
        createdAt: DateTime(2020),
      );
      expect(inProgress.statusLabel, 'قيد المعالجة');
      expect(inProgress.statusColor, const Color(0xFF1E88E5));
    });
  });

  group('EmergencyContact', () {
    test('isEmergency depends on type', () {
      final e = EmergencyContact.fromJson(
        {'name': 'شرطة', 'phone': '122', 'type': 'emergency'},
        'e1',
      );
      expect(e.isEmergency, isTrue);
      final c = EmergencyContact.fromJson(
        {'name': 'لجنة', 'phone': '123', 'type': 'community'},
        'e2',
      );
      expect(c.isEmergency, isFalse);
    });
  });

  group('Obituary / Occasion', () {
    test('Obituary fromJson/toJson', () {
      final o = Obituary.fromJson(
        {'name': 'محمد', 'age': '70', 'date': '2020', 'description': 'د', 'place': 'p', 'mosque': 'm', 'isApproved': true},
        'o1',
      );
      expect(o.name, 'محمد');
      expect(o.isApproved, isTrue);
      expect(o.toJson()['mosque'], 'm');
    });

    test('Occasion fromJson/toJson', () {
      final o = Occasion.fromJson(
        {'title': 'فرح', 'date': '2020', 'description': 'د', 'location': 'ل', 'organizer': 'منظم', 'isApproved': true},
        'oc1',
      );
      expect(o.title, 'فرح');
      expect(o.organizer, 'منظم');
      expect(o.toJson()['location'], 'ل');
    });
  });

  group('ForumPost / PhoneDirectoryEntry / Review / Order / VillageInfo', () {
    test('ForumPost likes tracking', () {
      final p = ForumPost.fromJson(
        {'userId': 'u', 'userName': 'ن', 'content': 'محتوى', 'likes': 2, 'comments': 1, 'isApproved': true},
        'f1',
      );
      expect(p.isLikedBy('u'), isFalse);
      expect(p.isLikedBy('other'), isFalse);
      expect(p.likedBy, isEmpty);
    });

    test('PhoneDirectoryEntry', () {
      final e = PhoneDirectoryEntry.fromJson(
        {'name': 'أحمد', 'title': 'مهندس', 'phone': '111', 'job': 'برمجة', 'address': 'عنوان'},
        'ph1',
      );
      expect(e.name, 'أحمد');
      expect(e.job, 'برمجة');
      expect(e.toJson()['phone'], '111');
    });

    test('AppOrder status mapping', () {
      final o = AppOrder(
        id: 'o1',
        productId: 'p',
        productName: 'منتج',
        price: 10,
        quantity: 2,
        buyerId: 'b',
        buyerName: 'مشتري',
        buyerPhone: '999',
        sellerId: 's',
        status: 'delivered',
        createdAt: DateTime(2020),
      );
      expect(o.statusLabel, 'تم التسليم');
      expect(o.statusColor, const Color(0xFF6F4E37));
    });

    test('VillageInfo defaults are non-empty', () {
      final v = VillageInfo.defaults();
      expect(v.name, isNotEmpty);
      expect(v.history.length, greaterThan(0));
      expect(v.institutions.length, greaterThan(0));
      expect(v.archive.length, greaterThan(0));
      final json = v.toJson();
      expect(json['population'], isNotEmpty);
    });

    test('VillageInfo fromJson fills defaults', () {
      final v = VillageInfo.fromJson({'name': 'قرية'}, 'main');
      expect(v.name, 'قرية');
      expect(v.population, '');
      expect(v.history, isEmpty);
    });
  });

  group('UserModel', () {
    test('copyWith and role flags', () {
      final u = UserModel(
        id: 'u1',
        name: 'مستخدم',
        email: 'a@b.com',
        joinDate: DateTime(2020),
        role: 'admin',
      );
      expect(u.isAdmin, isTrue);
      expect(u.isModerator, isTrue);
      final copy = u.copyWith(name: 'جديد');
      expect(copy.name, 'جديد');
      expect(copy.role, 'admin');
    });

    test('roleLabel covers all defined roles', () {
      String labelFor(String r) => UserModel(
            id: 'u',
            name: 'ن',
            email: 'e',
            joinDate: DateTime(2024),
            role: r,
          ).roleLabel;
      expect(labelFor('user'), 'مستخدم');
      expect(labelFor('seller'), 'بائع');
      expect(labelFor('moderator'), 'مشرف');
      expect(labelFor('medical_admin'), 'مدير المركز الطبي');
      expect(labelFor('admin'), 'مدير عام');
      expect(labelFor('unknown'), 'unknown');
    });

    test('medical_admin counts as moderator but not as admin', () {
      final u = UserModel(
        id: 'u',
        name: 'ن',
        email: 'e',
        joinDate: DateTime(2024),
        role: 'medical_admin',
      );
      expect(u.isAdmin, isFalse);
      expect(u.isModerator, isTrue);
      expect(u.canAccessAdminPanel, isTrue);
    });
  });
}
