import 'package:flutter/material.dart';

import '/api_service.dart';

Future<bool> deleteTeacherMaterial({
  required BuildContext context,
  required String token,
  required int materialId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 40),
        title: const Text('Delete Material'),
        content: const Text(
          'Are you sure you want to delete this material? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return false;
  }

  try {
    await ApiService.deleteTeacherMaterial(
      token: token,
      materialId: materialId,
    );

    if (!context.mounted) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Material deleted successfully.'),
        backgroundColor: Colors.green,
      ),
    );

    return true;
  } catch (e) {
    if (!context.mounted) {
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );

    return false;
  }
}
