import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SuggestionChips extends StatelessWidget {
  final Function(String) onChipTapped;

  const SuggestionChips({super.key, required this.onChipTapped});

  static const List<Map<String, dynamic>> _suggestions = [
    {'label': '💰 Check Dues', 'action': 'Do I have any dues?'},
    {'label': '📜 Request Certificate', 'action': 'I need a certificate'},
    {'label': '🌟 Opportunities', 'action': 'Show me opportunities'},
    {'label': '🔧 Report Issue', 'action': 'I want to report an issue'},
    {'label': '📁 My Documents', 'action': 'Show my documents'},
    {'label': '💳 Payments', 'action': 'Show my fee details'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onChipTapped(suggestion['action'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      suggestion['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
