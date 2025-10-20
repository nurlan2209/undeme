import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class EmergencyContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final String relation;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const EmergencyContactCard({
    Key? key,
    required this.name,
    required this.phone,
    required this.relation,
    required this.onEdit,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  _buildButton('Өзгерту', onEdit),
                  const SizedBox(width: 8),
                  _buildButton('Жою', onRemove),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(phone, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(relation, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
    );
  }
}
