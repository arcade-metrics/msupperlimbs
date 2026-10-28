import 'package:flutter/material.dart';

class NumberFieldWidget extends StatelessWidget {
  final String label;
  final String? helperText;
  final TextEditingController controller;
  final void Function(String) onChanged;
  final double fieldWidth;

  const NumberFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.helperText,
    this.fieldWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                helperText!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}
