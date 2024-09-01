import 'package:flutter/material.dart';

class LoadingOverlay {
  static void show(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          alignment: Alignment.center,
          height: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 15),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
