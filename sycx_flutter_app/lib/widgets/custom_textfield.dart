import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final bool obscureText;
  final String? Function(String?) validator;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.obscureText = false,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
