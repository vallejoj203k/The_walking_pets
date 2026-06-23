import 'package:flutter/material.dart';
import '../../../core/models/pet_model.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class PetCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onDelete;

  const PetCard({super.key, required this.pet, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accentLight,
          child: Text(pet.typeEmoji, style: const TextStyle(fontSize: 22)),
        ),
        title: Text(pet.name, style: AppTextStyles.heading3),
        subtitle: Text(
          '${_capitalize(pet.type)} · ${_capitalize(pet.size)}',
          style: AppTextStyles.bodySecondary,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Eliminar mascota'),
                content: Text(
                    '¿Seguro que quieres eliminar a ${pet.name}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Eliminar',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
            if (confirm == true) onDelete();
          },
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
