import 'package:flutter/material.dart';
import '../core/theme.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accent, size: 36),
        title: Text(title, style: AppTextStyles.cardTitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
