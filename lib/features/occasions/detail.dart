import 'package:flutter/material.dart';
import '../../models/data_models.dart';
import '../../widgets/common_appbar_actions.dart';

class OccasionDetailScreen extends StatelessWidget {
  const OccasionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final occasion = args is Occasion
        ? args
        : const Occasion(
            id: '',
            title: 'عيد الوالدين',
            date: '2024/6/17',
            description: 'حفلة خاصة بتكريم أهل القرية وكبارهم.',
            location: 'مركز المناسبات',
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(occasion.title),
        actions: CommonAppBarActions.actions(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.orange.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: occasion.imageUrl != null && occasion.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        occasion.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(child: Icon(Icons.card_giftcard, size: 100)),
            ),
            const SizedBox(height: 16),
            Text(
              occasion.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(occasion.date, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(occasion.location, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'الوصف',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              occasion.description,
              style: const TextStyle(height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.event),
                label: const Text('المشاركة بالحفل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
