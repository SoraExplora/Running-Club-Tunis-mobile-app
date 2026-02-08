import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/assistant_service.dart';

import '../utils/accessibility_utils.dart';

class AssistantOverlay extends StatelessWidget {
  const AssistantOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Consumer<AssistantService>(
        builder: (context, assistant, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (assistant.isThinking)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              Stack(
                alignment: Alignment.center,
                children: [
                  if (assistant.isListening)
                    Container(
                      width: 60 + (assistant.soundLevel * 2),
                      height: 60 + (assistant.soundLevel * 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                  GestureDetector(
                    onLongPress: () {
                      final layout =
                          AccessibilityUtils.getScreenLayout(context);
                      if (kDebugMode) print('Debug message (command): $layout');
                      assistant.handleVoiceCommand(layout);
                    },
                    child: FloatingActionButton(
                      onPressed: () {
                        final layout =
                            AccessibilityUtils.getScreenLayout(context);
                        if (kDebugMode) print('Debug message: $layout');
                        assistant.describeScreen(layout);
                      },
                      backgroundColor: assistant.isListening
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      child: Icon(
                        assistant.isListening ? Icons.mic : Icons.assistant,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}