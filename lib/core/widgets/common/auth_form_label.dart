import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class AuthFormLabel extends StatelessWidget {
  const AuthFormLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.info,
      ),
    );
  }
}
