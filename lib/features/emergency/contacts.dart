import 'package:flutter/material.dart';
import '../../widgets/common_appbar_actions.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطوارئ'),
        actions: CommonAppBarActions.actions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.emergency, size: 48, color: Colors.red),
                Text(
                  'الطوارئ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('اتصل بنا فوراً'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildEmergencyItem('شرطة القرية', '0123456789', Icons.security),
          _buildEmergencyItem(
            'إطفاء القرية',
            '0123456780',
            Icons.local_fire_department,
          ),
          _buildEmergencyItem(
            'مستشفى القرية',
            '0123456781',
            Icons.local_hospital,
          ),
          _buildEmergencyItem(
            'عربة الإسعاف',
            '0123456782',
            Icons.local_hospital,
          ),
          const SizedBox(height: 20),
          const Text(
            'خدمات مجتمعية:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          _buildEmergencyItem('لجنة القرية', '0123456783', Icons.groups),
          _buildEmergencyItem('الشرطة النسائية', '0123456784', Icons.person),
        ],
      ),
    );
  }

  Widget _buildEmergencyItem(String title, String phone, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(phone),
        trailing: IconButton(icon: const Icon(Icons.call), onPressed: () {}),
      ),
    );
  }
}