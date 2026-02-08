import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import '../main.dart';

class AccessibilityUtils {
  // Store RenderObjects associated with IDs for the current screen
  static final Map<String, RenderObject> _renderObjects = {};

  static String getScreenLayout(BuildContext context) {
    // Reset for new analysis
    _renderObjects.clear();
    final idCounts = <String, int>{};
    final buffer = StringBuffer();
    final addedTexts = <String>{};

    try {
      // Try to get route from context
      ModalRoute? route = ModalRoute.of(context);
      
      if (route == null) {
        // Fallback: If no route found, try to walk the navigator's context or the root element
        final navState = RCTConnectApp.navigatorKey.currentState;
        final rootElement = navState?.context ?? WidgetsBinding.instance.rootElement;
        
        if (rootElement != null) {
           _analyzeElementTree(rootElement as Element, buffer, addedTexts, idCounts);
           final result = buffer.toString();
           return result.isEmpty ? "L'écran semble vide." : result;
        }
      }

      if (route == null) return "Aucun écran détecté.";

      void walker(Element el, String? label) {
        _visitElementNode(el, buffer, addedTexts, idCounts, inheritedLabel: label, onDescend: walker);
      }

      void visitElement(Element element) {
        walker(element, null);
      }

      if (route.subtreeContext != null) {
        (route.subtreeContext as Element).visitChildren((child) => visitElement(child));
      } else {
        return "Impossible d'analyser l'écran.";
      }

      final result = buffer.toString();
      return result.isEmpty ? "L'écran semble vide." : result;
    } catch (e) {
      return "Erreur lors de l'analyse: $e";
    }
  }

  static void _analyzeElementTree(Element element, StringBuffer buffer, Set<String> addedTexts, Map<String, int> idCounts) {
    // A simplified walker that doesn't care about Routes
    void walker(Element el, String? label) {
       // Similar logic to visitElement but static/captured
       // We'll reuse the logic by making it more general
       _visitElementNode(el, buffer, addedTexts, idCounts, inheritedLabel: label, onDescend: walker);
    }
    walker(element, null);
  }

  static void _visitElementNode(
    Element element, 
    StringBuffer buffer, 
    Set<String> addedTexts, 
    Map<String, int> idCounts, 
    {String? inheritedLabel, 
    required void Function(Element, String?) onDescend}
  ) {
    String? text;
    bool isInteractive = false;

    // Standard detection logic
    if (element.widget is ButtonStyleButton ||
        element.widget is InkWell ||
        element.widget is IconButton ||
        element.widget is FloatingActionButton ||
        element.widget is PopupMenuButton ||
        element.widget is GestureDetector) {
      isInteractive = true;
    }

    if (element.widget is Text) {
      final textWidget = element.widget as Text;
      text = textWidget.data ?? textWidget.textSpan?.toPlainText();
    } else if (element.widget is RichText) {
      text = (element.widget as RichText).text.toPlainText();
    } else if (element.widget is Semantics) {
      final semantics = element.widget as Semantics;
      if (semantics.properties.onTap != null) isInteractive = true;
      text = semantics.properties.label ?? semantics.properties.value ?? semantics.properties.hint;
    } else if (element.widget is TextField) {
      final tf = element.widget as TextField;
      text = "Champ: ${tf.decoration?.labelText ?? tf.decoration?.hintText ?? 'texte'}";
      isInteractive = true;
    }

    if (text == null && isInteractive && inheritedLabel != null) {
      text = inheritedLabel;
    }

    if (text != null && text.trim().isNotEmpty) {
      String logEntry = text.trim();
      if (isInteractive) {
        final id = _generateId(logEntry, idCounts);
        _renderObjects[id] = element.renderObject!;
        logEntry = "[$id] $logEntry (Interactif)";
      }
      if (addedTexts.add(logEntry)) {
        buffer.writeln("- $logEntry");
      }
    }

    element.visitChildren((child) => onDescend(child, inheritedLabel));
  }

  static String _generateId(String text, Map<String, int> counts) {
    // Slugify text: lowercase, remove accents, replace spaces/special chars with _
    String base = text.toLowerCase().trim();
    base = base.replaceAll(RegExp(r'[àáâãäå]'), 'a');
    base = base.replaceAll(RegExp(r'[ç]'), 'c');
    base = base.replaceAll(RegExp(r'[èéêë]'), 'e');
    base = base.replaceAll(RegExp(r'[ìíîï]'), 'i');
    base = base.replaceAll(RegExp(r'[òóôõö]'), 'o');
    base = base.replaceAll(RegExp(r'[ùúûü]'), 'u');
    base = base.replaceAll(RegExp(r'[ýÿ]'), 'y');
    base = base.replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    // Trim underscores from start/end
    base = base.replaceAll(RegExp(r'^_+|_+$'), '');

    if (base.isEmpty) base = "element";

    // Handle duplicates
    int count = counts[base] ?? 0;
    counts[base] = count + 1;

    return count == 0 ? base : "${base}_${count + 1}";
  }

  static Future<void> simulateTap(String id) async {
    final renderObject = _renderObjects[id];
    if (renderObject == null || !renderObject.attached) {
    if (kDebugMode) print("Element [$id] not found or detached.");
      return;
    }

    if (renderObject is RenderBox) {
      final center =
          renderObject.localToGlobal(renderObject.size.center(Offset.zero));

      final hitTestResult = HitTestResult();
      // Using hitTest from RendererBinding for modern compatibility
      RendererBinding.instance.renderViews.first.hitTest(hitTestResult, position: center);

      final pointerDownEvent = PointerDownEvent(
        position: center,
        kind: PointerDeviceKind.touch,
      );

      GestureBinding.instance.handlePointerEvent(pointerDownEvent);

      await Future.delayed(const Duration(milliseconds: 100));

      final pointerUpEvent = PointerUpEvent(
        position: center,
        kind: PointerDeviceKind.touch,
      );

      GestureBinding.instance.handlePointerEvent(pointerUpEvent);
      if (kDebugMode) print("Simulated tap on element [$id] at $center");
    }
  }
}