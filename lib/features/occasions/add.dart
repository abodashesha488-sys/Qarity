import 'package:flutter/material.dart';

class AddOccasionScreen extends StatelessWidget {
  const AddOccasionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مناسبة')),
      body: const Center(child: Text('شاشة إضافة المناسبات')),
    );
  }
}