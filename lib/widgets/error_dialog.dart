import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String message;
  final String? title;

  const ErrorDialog({super.key, required this.message, this.title});

  static Future<void> show(BuildContext context, String message,
      {String? title}) {
    return showDialog(
      context: context,
      builder: (_) => ErrorDialog(message: message, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
