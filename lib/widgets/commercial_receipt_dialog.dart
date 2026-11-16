import 'package:flutter/material.dart';

import '../core/utils/app_image_cache.dart';
import '../models/eshterili_model.dart';
import '../models/etsawaqli_model.dart';
import '../models/group_deal_model.dart';
import '../services/share_service.dart';

/// نافذة وحوار الفاتورة / الإيصال المعتمد للطباعة والمشاركة
/// لجميع خدمات التجارة والتسوق بالقرية:
/// 1- صفقة اليوم (إيصال حجز صفقة جملة)
/// 2- إشتريلي (فاتورة طلب شراء وتوصيل)
/// 3- إتسوقلي (فاتورة كاشير مشتريات سوق القرية)
class CommercialReceiptDialog {
  CommercialReceiptDialog._();

  // =========================================================================
  // 1. إيصال حجز صفقة الجملة
  // =========================================================================

  static void showDealReceipt(
    BuildContext context, {
    required GroupDealModel deal,
    required DealParticipantModel participant,
  }) {
    final totalPrice = participant.totalAmount(deal.dealPrice);
    final totalSavings = participant.quantity * deal.savingPerUnit;
    final marketVal = participant.quantity * deal.marketPrice;

    final formattedText = StringBuffer()
      ..writeln('🧾 ═════════════════════════════════')
      ..writeln('   منظومة التجارة والتسوق — قرية أبودشيشة')
      ..writeln('       إيصال حجز صفقة جملة رسمية')
      ..writeln('═════════════════════════════════')
      ..writeln('▫️ اسم الصفقة: ${deal.title}')
      ..writeln('▫️ اسم المشترك: ${participant.userName}')
      ..writeln('▫️ رقم الهاتف: ${participant.userPhone}')
      ..writeln('▫️ الكمية المحجوزة: ${participant.quantity} ${deal.unitName}')
      ..writeln('▫️ سعر الجملة للوحدة: ${deal.dealPrice.toStringAsFixed(0)} ج (السوق: ${deal.marketPrice.toStringAsFixed(0)} ج)')
      ..writeln('▫️ طريقة الاستلام: ${participant.deliveryOption == "home" ? "توصيل منزلي (+${participant.deliveryFee.toStringAsFixed(0)} ج)" : "مقر التوزيع الرئيسي (مجاناً)"}')
      ..writeln('---------------------------------')
      ..writeln('▫️ القيمة الإجمالية بالسوق: ${marketVal.toStringAsFixed(0)} ج')
      ..writeln('▫️ الإجمالي المطلوب عند الاستلام: ${totalPrice.toStringAsFixed(0)} ج')
      ..writeln('▫️ إجمالي الوفورات المحققة: ${totalSavings.toStringAsFixed(0)} ج 🎉')
      ..writeln('---------------------------------')
      ..writeln('🔑 كود الاستلام السري: [ ${participant.claimCode} ]')
      ..writeln('⚠️ يرجى إبراز هذا الكود لمندوب التسليم لتأكيد الاستلام.')
      ..writeln('حالة الحجز: ${participant.isDelivered ? "تم التسليم بنجاح ✅" : (participant.isConfirmedByAdmin ? "مؤكد وجارٍ التجهيز 📦" : "قيد المراجعة ⏳")}')
      ..writeln('═════════════════════════════════');

    _showReceiptModal(
      context: context,
      title: 'إيصال حجز صفقة جملة',
      serviceBadge: 'صفقات الجملة 🔥',
      badgeColor: const Color(0xFF16A34A),
      shareTitle: 'إيصال حجز صفقة: ${deal.title}',
      shareBody: formattedText.toString(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReceiptHeader(
            title: 'إيصال حجز صفقة جملة',
            subtitle: deal.title,
            receiptNumber: 'DL-${participant.id.length > 6 ? participant.id.substring(0, 6).toUpperCase() : participant.id.toUpperCase()}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow('اسم المشترك:', participant.userName),
          _buildInfoRow('رقم الهاتف:', participant.userPhone),
          _buildInfoRow('الكمية:', '${participant.quantity} ${deal.unitName}'),
          _buildInfoRow('سعر الوحدة بالجملة:', '${deal.dealPrice.toStringAsFixed(0)} جنيه'),
          _buildInfoRow('سعر السوق الفعلي:', '${deal.marketPrice.toStringAsFixed(0)} جنيه'),
          if (participant.deliveryOption == 'home') ...[
            _buildInfoRow('طريقة الاستلام:', 'توصيل منزلي (+${participant.deliveryFee.toStringAsFixed(0)} ج)'),
            if (participant.deliveryAddress.isNotEmpty)
              _buildInfoRow('عنوان التوصيل:', participant.deliveryAddress),
          ] else ...[
            _buildInfoRow('طريقة الاستلام:', 'مقر التوزيع بالقرية (مجاناً)'),
          ],
          const Divider(height: 20),
          _buildTotalRow('الإجمالي المطلوب عند الاستلام:', '${totalPrice.toStringAsFixed(0)} جنيه', isHighlight: true),
          if (totalSavings > 0)
            _buildTotalRow('قيمة ما وفرته مع القرية:', '${totalSavings.toStringAsFixed(0)} جنيه 🎉', color: const Color(0xFF16A34A)),
          const SizedBox(height: 14),
          _buildClaimCodeBox(participant.claimCode, participant.isDelivered),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. فاتورة طلب شراء وتوصيل (إشتريلي)
  // =========================================================================

  static void showEshteriliReceipt(
    BuildContext context, {
    required EshteriliOrder order,
  }) {
    final formattedText = StringBuffer()
      ..writeln('🧾 ═════════════════════════════════')
      ..writeln('   منظومة التجارة والتسوق — قرية أبودشيشة')
      ..writeln('       فاتورة خدمة إشتريلي (مندوب القرية)')
      ..writeln('═════════════════════════════════')
      ..writeln('▫️ رقم الطلب: ${order.orderNumber}')
      ..writeln('▫️ العميل: ${order.userName}')
      ..writeln('▫️ الهاتف: ${order.userPhone}')
      ..writeln('▫️ عنوان التوصيل: ${order.deliveryAddress}')
      ..writeln('▫️ مكان الشراء: ${order.storeOrArea.isEmpty ? "حسب المتاح" : order.storeOrArea}')
      ..writeln('---------------------------------')
      ..writeln('▫️ بيان المشتريات:')
      ..writeln(order.itemsDescription)
      ..writeln('---------------------------------')
      ..writeln('▫️ تكلفة المشتريات: ${order.itemCost.toStringAsFixed(0)} ج')
      ..writeln('▫️ رسوم الخدمة والعمولة: ${order.serviceFee.toStringAsFixed(0)} ج')
      ..writeln('▫️ مصاريف التوصيل: ${order.deliveryFee.toStringAsFixed(0)} ج')
      ..writeln('---------------------------------')
      ..writeln('▫️ المبلغ الإجمالي المستحق: ${order.totalAmount.toStringAsFixed(0)} ج')
      ..writeln('---------------------------------')
      ..writeln('🔑 كود الاستلام السري: [ ${order.claimCode} ]')
      ..writeln('⚠️ يُعطى الكود للمندوب فقط عند استلام المشتريات والتأكد منها.')
      ..writeln('حالة الطلب: ${order.status.labelArabic}')
      ..writeln('═════════════════════════════════');

    _showReceiptModal(
      context: context,
      title: 'فاتورة خدمة إشتريلي',
      serviceBadge: 'إشتريلي 🛵',
      badgeColor: const Color(0xFF2563EB),
      shareTitle: 'فاتورة طلب إشتريلي رقم ${order.orderNumber}',
      shareBody: formattedText.toString(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReceiptHeader(
            title: 'فاتورة شراء وتوصيل',
            subtitle: 'خدمة إشتريلي — مندوب القرية',
            receiptNumber: order.orderNumber,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('العميل:', order.userName),
          _buildInfoRow('الهاتف:', order.userPhone),
          _buildInfoRow('العنوان:', order.deliveryAddress),
          if (order.storeOrArea.isNotEmpty)
            _buildInfoRow('مكان الشراء:', order.storeOrArea),
          const Divider(height: 16),
          const Text('بيان الطلب والمشتريات:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(order.itemsDescription, style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
          ),
          const Divider(height: 16),
          _buildInfoRow('قيمة المشتريات:', '${order.itemCost.toStringAsFixed(0)} ج'),
          _buildInfoRow('رسوم الخدمة:', '${order.serviceFee.toStringAsFixed(0)} ج'),
          _buildInfoRow('مصاريف التوصيل:', '${order.deliveryFee.toStringAsFixed(0)} ج'),
          const Divider(height: 16),
          _buildTotalRow('المبلغ الإجمالي المستحق:', '${order.totalAmount.toStringAsFixed(0)} جنيه', isHighlight: true),
          if (order.receiptImageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('صورة فاتورة المحل المرفقة من المندوب:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppImageCache.image(
                url: order.receiptImageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _buildClaimCodeBox(order.claimCode, order.status == EshteriliStatus.completed),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. فاتورة كاشير مشتريات سوق القرية (إتسوقلي)
  // =========================================================================

  static void showEtsawaqliReceipt(
    BuildContext context, {
    required EtsawaqliOrder order,
  }) {
    final orderNum = order.invoiceNumber.isNotEmpty ? order.invoiceNumber : order.id;

    final formattedText = StringBuffer()
      ..writeln('🧾 ═════════════════════════════════')
      ..writeln('   منظومة التجارة والتسوق — قرية أبودشيشة')
      ..writeln('       فاتورة كاشير سوق الجمعة (إتسوقلي)')
      ..writeln('═════════════════════════════════')
      ..writeln('▫️ رقم الفاتورة: $orderNum')
      ..writeln('▫️ اسم السوق: ${order.marketName}')
      ..writeln('▫️ المشترك: ${order.userName}')
      ..writeln('▫️ الهاتف: ${order.userPhone}')
      ..writeln('▫️ عنوان التوصيل: ${order.deliveryAddress}')
      ..writeln('---------------------------------')
      ..writeln('   قائمة المشتريات:')
      ..writeln('---------------------------------');

    for (final item in order.items) {
      formattedText.writeln('• ${item.productName}: ${item.quantity} ${item.unit} × ${item.unitPrice.toStringAsFixed(0)} ج = ${item.totalPrice.toStringAsFixed(0)} ج');
    }

    formattedText
      ..writeln('---------------------------------')
      ..writeln('▫️ إجمالي السلع: ${order.itemsSubtotal.toStringAsFixed(0)} ج')
      ..writeln('▫️ رسوم التسوق: ${order.serviceFee.toStringAsFixed(0)} ج')
      ..writeln('▫️ مصاريف التوصيل: ${order.deliveryFee.toStringAsFixed(0)} ج')
      ..writeln('---------------------------------')
      ..writeln('▫️ المبلغ الإجمالي للفاتورة: ${order.totalAmount.toStringAsFixed(0)} ج')
      ..writeln('---------------------------------')
      ..writeln('📌 ملاحظة هامة:')
      ..writeln('"${order.marketNotice}"')
      ..writeln('═════════════════════════════════');

    _showReceiptModal(
      context: context,
      title: 'فاتورة كاشير إتسوقلي',
      serviceBadge: 'إتسوقلي 🧺',
      badgeColor: const Color(0xFF16A34A),
      shareTitle: 'فاتورة كاشير سوق الجمعة رقم $orderNum',
      shareBody: formattedText.toString(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReceiptHeader(
            title: 'فاتورة كاشير مشتريات',
            subtitle: order.marketName.isEmpty ? 'سوق الجمعة بأبودشيشة' : order.marketName,
            receiptNumber: orderNum,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('العميل:', order.userName),
          _buildInfoRow('الهاتف:', order.userPhone),
          _buildInfoRow('العنوان:', order.deliveryAddress),
          const Divider(height: 16),
          const Text('الأصناف والسلع المختارة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '• ${item.productName} (${item.quantity} ${item.unit})',
                            style: const TextStyle(fontSize: 11, fontFamily: 'Cairo'),
                          ),
                        ),
                        Text(
                          '${item.totalPrice.toStringAsFixed(0)} ج',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 16),
          _buildInfoRow('إجمالي السلع:', '${order.itemsSubtotal.toStringAsFixed(0)} ج'),
          _buildInfoRow('رسوم التسوق:', '${order.serviceFee.toStringAsFixed(0)} ج'),
          _buildInfoRow('مصاريف التوصيل:', '${order.deliveryFee.toStringAsFixed(0)} ج'),
          const Divider(height: 16),
          _buildTotalRow('الإجمالي المستحق:', '${order.totalAmount.toStringAsFixed(0)} جنيه', isHighlight: true),
          const SizedBox(height: 12),
          // الملاحظة الإلزامية للمستهلك
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              order.marketNotice,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF92400E),
                height: 1.4,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // دوال مساعدة في بناء وتنسيق الفاتورة
  // =========================================================================

  static void _showReceiptModal({
    required BuildContext context,
    required String title,
    required String serviceBadge,
    required Color badgeColor,
    required String shareTitle,
    required String shareBody,
    required Widget content,
  }) {
    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  serviceBadge,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor, fontFamily: 'Cairo'),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(dlgContext),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: content,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(dlgContext),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: badgeColor),
              onPressed: () {
                ShareService.shareText(
                  title: shareTitle,
                  body: shareBody,
                );
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('طباعة ومشاركة الفاتورة 🖨️', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildReceiptHeader({
    required String title,
    required String subtitle,
    required String receiptNumber,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          const Text('🏪 قرية أبودشيشة — منصة الخدمات المجتمعية', style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, fontFamily: 'Cairo')),
          const SizedBox(height: 4),
          Text('رقم السجل: $receiptNumber', style: const TextStyle(fontSize: 10, letterSpacing: 1.2, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.black54, fontFamily: 'Cairo')),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTotalRow(String label, String value, {bool isHighlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 13 : 11.5,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 14 : 12,
              fontWeight: FontWeight.w900,
              color: color ?? (isHighlight ? const Color(0xFFB45309) : null),
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildClaimCodeBox(String code, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_rounded, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('كود الاستلام السري لمندوب التوصيل:', style: TextStyle(fontSize: 10, color: Color(0xFF92400E), fontFamily: 'Cairo')),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Color(0xFFB45309),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('مُستلم ✅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontFamily: 'Cairo')),
            ),
        ],
      ),
    );
  }
}
