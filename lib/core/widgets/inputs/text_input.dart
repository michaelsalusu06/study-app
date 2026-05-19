import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_sizes.dart';

/// Custom text input widget with validation and modern styling
class TextInput extends StatelessWidget {
  const TextInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.initialValue,
    this.fillColor,
    this.borderColor,
    this.borderRadius, 
    this.validator,
    this.size = InputSize.medium,
    this.showBorder = true,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? initialValue;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius; 
  final String? Function(String?)? validator;
  final InputSize size;
  final bool showBorder;

  double get _contentPadding {
    switch (size) {
      case InputSize.small:
        return AppSizes.sm;
      case InputSize.medium:
        return AppSizes.md;
    }
  }

  double get _fontSize => size == InputSize.small ? 14 : 16;

  
  double get _effectiveRadius => borderRadius ?? AppSizes.radiusMd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final effectiveFillColor = fillColor ?? colorScheme.surface;
    final effectiveBorderColor = borderColor ?? colorScheme.outline;
    // Compute once and reuse across all 5 border instances
    final br = br;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: textTheme.titleSmall?.copyWith(
              color: enabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          focusNode: focusNode,
          autofocus: autofocus,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          validator: validator,
          style: textTheme.bodyLarge?.copyWith(
            fontSize: _fontSize,
            color: enabled
                ? colorScheme.onSurface
                : colorScheme.onSurface.withOpacity(0.5),
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            helperText: helperText,
            filled: true,
            fillColor: effectiveFillColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: _contentPadding,
              vertical: _contentPadding,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: _fontSize + 4,
                    color: borderColor ?? (enabled
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface.withOpacity(0.38)),
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      suffixIcon,
                      size: _fontSize + 4,
                      color: borderColor ?? (enabled
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface.withOpacity(0.38)),
                    ),
                    onPressed: onSuffixIconPressed,
                  )
                : null,
            border: showBorder
                ? OutlineInputBorder(
                    borderRadius: br,
                    borderSide: BorderSide(color: effectiveBorderColor),
                  )
                : OutlineInputBorder(
                    borderRadius: br,
                    borderSide: BorderSide.none,
                  ),
            enabledBorder: showBorder
                ? OutlineInputBorder(
                    borderRadius: br,
                    borderSide: BorderSide(
                      color: effectiveBorderColor,
                      width: 1.5,
                    ),
                  )
                : OutlineInputBorder(
                    borderRadius: br,
                    borderSide: BorderSide.none,
                  ),
            focusedBorder: OutlineInputBorder(
              borderRadius: br,
              borderSide: BorderSide(
                color: borderColor ?? colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: br,
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: br,
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
            disabledBorder: showBorder
                ? OutlineInputBorder(
                    borderRadius: br,
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.12),
                    ),
                  )
                : OutlineInputBorder(
                    borderRadius: br,
                    borderSide: BorderSide.none,
                  ),
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            errorStyle: textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
            helperStyle: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

enum InputSize { small, medium }