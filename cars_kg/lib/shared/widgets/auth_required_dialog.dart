import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showAuthRequiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Login required'),
      content: const Text(
        'You can browse listings as a guest, but this action requires authentication.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/login');
          },
          child: const Text('Login'),
        ),
      ],
    ),
  );
}
