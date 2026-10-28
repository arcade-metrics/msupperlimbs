import 'package:flutter/material.dart';

/// Logo light/dark do app legado.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 100});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark
          ? 'assets/logo-dark-1024x1024.png'
          : 'assets/logo-light-1024x1024.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
