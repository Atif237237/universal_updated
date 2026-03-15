import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool isReadOnly; // Added for fields that shouldn't be edited
  final String? Function(String?)? validator; // Added for form validation

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.isReadOnly = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Using TextFormField for validation support
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      readOnly: isReadOnly,
      validator: validator,
      decoration: InputDecoration(
        // hintText ab labelText ban gaya hai, jo aacha look deta hai
        labelText: hintText,

        prefixIcon: prefixIcon != null
            // 1. Icon se hardcoded color hata diya gaya hai.
            // Yeh ab theme ke hisab se aapas ko set karega.
            ? Icon(prefixIcon)
            : null,

        filled: true,
        // 2. fillColor bhi hata diya gaya hai.
        // Theme ab light mode mein halka grey aur dark mode mein gehra grey rang dega.
        // fillColor: AppColors.lightGrey, <--- REMOVED

        // Consistent border style
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // No border needed when filled
        ),

        // Focused border to highlight active field
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          // It will use theme's primary color for the border
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),

        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }
}
