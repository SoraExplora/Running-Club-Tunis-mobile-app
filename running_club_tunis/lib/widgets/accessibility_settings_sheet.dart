import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/accessible_colors.dart';
 // For AppTheme but colors come from service now

class AccessibilitySettingsSheet extends StatelessWidget {
  const AccessibilitySettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // We use hardcoded colors for the sheet background to ensure visibility during transitions
    final bg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? Colors.white70 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            "Customize Appearance",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Adjust colors and text size for better readability.",
            style: TextStyle(
              fontSize: 14,
              color: textSub,
            ),
          ),
          const SizedBox(height: 32),

          // Color Blindness Modes
          Text(
            "Color Palette",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textMain,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ColorBlindnessMode.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final mode = ColorBlindnessMode.values[index];
                final isSelected = themeService.colorMode == mode;
                final colors = AccessibleColors.get(mode);

                return GestureDetector(
                  onTap: () => themeService.setColorMode(mode),
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? colors.terracotta : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Palette Preview
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: colors.ivory, // Background
                            ),
                            child: Stack(
                              children: [
                                // Accent circle
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: colors.terracotta,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                // Text lines
                                Positioned(
                                  bottom: 12,
                                  left: 8,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: colors.coffee,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 24,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: colors.stone,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                         Text(
                          _getShortName(mode),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: textMain,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Font Scaling
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Text Size",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                ),
              ),
              Text(
                "${(themeService.fontScale * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: themeService.currentColors.terracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.text_fields, size: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: themeService.currentColors.terracotta,
                    thumbColor: themeService.currentColors.terracotta,
                    inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                  ),
                  child: Slider(
                    value: themeService.fontScale,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    onChanged: (val) => themeService.setFontScale(val),
                  ),
                ),
              ),
              const Icon(Icons.text_fields, size: 24),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Reset Button
          Center(
            child: TextButton(
              onPressed: () {
                themeService.setColorMode(ColorBlindnessMode.normal);
                themeService.setFontScale(1.0);
              },
              style: TextButton.styleFrom(
                foregroundColor: textSub,
              ),
              child: const Text("Reset to default"),
            ),
          ),
        ],
      ),
    );
  }

  String _getShortName(ColorBlindnessMode mode) {
    switch (mode) {
      case ColorBlindnessMode.normal: return "Normal";
      case ColorBlindnessMode.protanopia: return "Protanopia";
      case ColorBlindnessMode.deuteranopia: return "Deuteranopia";
      case ColorBlindnessMode.tritanopia: return "Tritanopia";
      case ColorBlindnessMode.achromatopsia: return "Monochrome";
    }
  }
}
