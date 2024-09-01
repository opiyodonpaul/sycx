import 'package:flutter/material.dart';

class AnimatedButton extends StatelessWidget {
  final String text;
  final Function onPressed;

  const AnimatedButton(
      {super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: () => onPressed(),
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
