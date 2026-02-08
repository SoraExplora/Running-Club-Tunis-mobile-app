import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/assistant_service.dart';

import '../utils/accessibility_utils.dart';

class AssistantFAB extends StatelessWidget {
  const AssistantFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AssistantService>(
      builder: (context, assistant, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (assistant.isThinking)
              const Padding(
                padding: EdgeInsets.only(bottom: 10, right: 8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            GestureDetector(
              onLongPress: () {
                final layout = AccessibilityUtils.getScreenLayout(context);
                if (kDebugMode) print('Debug message (command): $layout');
                assistant.handleVoiceCommand(layout);
              },
              child: Semantics(
                label: 'Assistant Vocal',
                child: FloatingActionButton(
                  onPressed: () {
                    final layout = AccessibilityUtils.getScreenLayout(context);
                    if (kDebugMode) print('Debug message: $layout');
                    assistant.describeScreen(layout);
                  },
                  mini: true,
                  backgroundColor:
                      assistant.isListening ? Colors.red : Theme.of(context).primaryColor,
                  child: Icon(
                    assistant.isListening ? Icons.mic : Icons.assistant,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}