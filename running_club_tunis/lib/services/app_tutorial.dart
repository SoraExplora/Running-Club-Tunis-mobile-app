import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTutorial {
  static const _seenKey = 'tutorial_seen_v1';

  TutorialCoachMark? _coachMark;

  Future<void> maybeStart({
    required BuildContext context,
    required List<TargetFocus> targets,
    bool force = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_seenKey) ?? false;

    if (!force && seen) return;

    if (!context.mounted) return;
    _coachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      textSkip: "Skip",
      paddingFocus: 10,
      pulseEnable: true,
      hideSkip: false,
      onFinish: () async {
        await prefs.setBool(_seenKey, true);
      },
      onSkip: () {
        prefs.setBool(_seenKey, true);
        return true;
      },
    )..show(context: context);
  }

  void stop() => _coachMark?.finish();
}
