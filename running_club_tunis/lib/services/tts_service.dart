import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class TtsService {
  FlutterTts? _flutterTts;
  bool _isPlaying = false;
  final bool _webSupported = kIsWeb && html.window.speechSynthesis != null;

  bool get isPlaying => _isPlaying;

  TtsService() {
    if (!kIsWeb) {
      _initializeTts();
    }
  }

  Future<void> _initializeTts() async {
    if (kIsWeb) return;
    try {
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage("fr-FR");
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);

      _flutterTts!.setStartHandler(() {
        _isPlaying = true;
      });

      _flutterTts!.setCompletionHandler(() {
        _isPlaying = false;
      });

      _flutterTts!.setErrorHandler((msg) {
        _isPlaying = false;
        if (kDebugMode) print("TTS Error: $msg");
      });
    } catch (e) {
      if (kDebugMode) print("TTS Initialization error: $e");
      _flutterTts = null;
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    if (kIsWeb) {
      if (kDebugMode) print("TTS (Web Fallback): $text");
      if (_webSupported) {
        try {
          final utterance = html.SpeechSynthesisUtterance(text);
          utterance.lang = 'fr-FR';
          utterance.rate = 1.0;
          html.window.speechSynthesis?.speak(utterance);
          return;
        } catch (e) {
          if (kDebugMode) print("Web SpeechSynthesis Error: $e");
        }
      }
      return; 
    }

    try {
      if (_flutterTts == null) {
        await _initializeTts();
      }
      await _flutterTts?.speak(text);
    } catch (e) {
      if (kDebugMode) print("TTS Speak Error: $e");
    }
  }

  Future<void> stop() async {
    if (kIsWeb) {
       if (_webSupported) html.window.speechSynthesis?.cancel();
       _isPlaying = false;
       return;
    }
    await _flutterTts?.stop();
    _isPlaying = false;
  }

  Future<void> setLanguage(String languageCode) async {
    await _flutterTts?.setLanguage(languageCode);
  }
}
