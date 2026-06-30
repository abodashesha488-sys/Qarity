import 'package:flutter/material.dart';
import '../../widgets/common_appbar_actions.dart';

class SellerGalleryScreen extends StatefulWidget {
  const SellerGalleryScreen({super.key});

  @override
  State<SellerGalleryScreen> createState() => _SellerGalleryScreenState();
}

class _SellerGalleryScreenState extends State<SellerGalleryScreen> {
  late final List<String> gallery;

  @override
  void initState() {
    super.initState();
    gallery = List.generate(
      8,
      (i) => 'https://picsum.photos/seed/${i + 1}/400/400',
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final seller = args is Map<String, String> ? args : {'name': 'بائع محلي'};
    final name = seller['name'] ?? 'بائع محلي';

    return Scaffold(
      appBar: AppBar(
        title: Text('$name - معرض'),
        actions: CommonAppBarActions.actions(context),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: gallery.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/market/0.jpg',
              image: gallery[index],
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              imageErrorBuilder: (context, error, stackTrace) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.broken_image, size: 40)),
              ),
            ),
          );
        },
      ),
    );
  }
}
