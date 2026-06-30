import 'package:flutter/material.dart';
import '../../models/data_models.dart';
import '../../widgets/common_appbar_actions.dart';

class ObituaryDetailScreen extends StatelessWidget {
  const ObituaryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final obituary = args is Obituary
        ? args
        : const Obituary(
            id: '',
            name: 'محمد أحمد محمد',
            age: '75',
            date: '2024/6/20',
            description: 'توفي بعد رحلة طويلة',
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الوفاة'),
        actions: CommonAppBarActions.actions(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
child: Column(
          children: [
            const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 80)),
            const SizedBox(height: 16),
            Text(
              obituary.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('عمر: ${obituary.age} سنة', style: const TextStyle(color: Colors.grey)),
            Text(
              'تاريخ الوفاة: ${obituary.date}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الوفاة', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(obituary.description),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.card_giftcard),
                label: const Text('تقديم التعازي'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}