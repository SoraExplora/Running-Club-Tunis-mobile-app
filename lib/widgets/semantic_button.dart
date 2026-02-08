import 'package:flutter/material.dart';

/// A wrapper widget that adds semantic identifiers to interactive elements
/// for improved accessibility and voice command recognition.
///
/// This widget wraps any child widget and attaches a semantic ID that can be
/// used by the voice command system to reliably identify and interact with
/// the element.
///
/// Example:
/// ```dart
/// SemanticButton(
///   semanticId: 'events_join_session',
///   child: ElevatedButton(
///     onPressed: () => joinSession(),
///     child: Text('Join'),
///   ),
/// )
/// ```
class SemanticButton extends StatelessWidget {
  /// The semantic identifier for this interactive element.
  /// Should follow the naming convention: `<screen>_<action>_<target>`
  /// Examples: 'events_join_session', 'profile_edit', 'home_notifications'
  final String semanticId;

  /// The interactive widget to wrap (Button, IconButton, InkWell, etc.)
  final Widget child;

  /// Optional label for screen readers
  final String? label;

  /// Optional hint about what this element does
  final String? hint;

  const SemanticButton({
    super.key,
    required this.semanticId,
    required this.child,
    this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticId,
      label: label,
      hint: hint,
      button: true,
      enabled: true,
      child: child,
    );
  }
}

/// A wrapper specifically for IconButtons with semantic IDs
class SemanticIconButton extends StatelessWidget {
  final String semanticId;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double? size;

  const SemanticIconButton({
    super.key,
    required this.semanticId,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticButton(
      semanticId: semanticId,
      label: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
