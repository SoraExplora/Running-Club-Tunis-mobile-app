import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'tts_service.dart';
import 'speech_service.dart';
import 'notification_service.dart';
import 'event_service.dart';
import 'auth_service.dart'; // Added
import 'package:provider/provider.dart';
import '../utils/accessibility_utils.dart';

class AssistantService extends ChangeNotifier {
  final TtsService _tts = TtsService();
  final SpeechService _speech = SpeechService();
  late GenerativeModel _model;
  final GlobalKey<NavigatorState> navigatorKey;

  bool _isListening = false;
  bool _isThinking = false;
  String _lastResponse = "";

  bool get isListening => _isListening;
  bool get isThinking => _isThinking;
  String get lastResponse => _lastResponse;
  double _soundLevel = 0.0;
  double get soundLevel => _soundLevel;

  AssistantService(this.navigatorKey) {
    _initAI();
  }

  void _initAI() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) print("WARNING: GEMINI_API_KEY is missing or empty!");
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey ?? "",
    );
  }

  Future<void> describeScreen(String screenLayout) async {
    if (screenLayout.isEmpty || screenLayout == "Aucun écran détecté.") {
      _lastResponse =
          "Je ne vois aucun élément interactif à décrire sur cet écran.";
      await _tts.speak(_lastResponse);
      return;
    }

    _isThinking = true;
    notifyListeners();

    if (kDebugMode) print('Debug message (describe): $screenLayout');

    final prompt = """
        Assure que le prompt est toujours en français
        and elements with low id represents element that are higher in the screen and elements with high id represents element that are lower in the screen
        Tu es un assistant d'accessibilité pour l'application RCT Connect. Voici les éléments de l'écran actuel (les nombres entre crochets [N] sont les identifiants des éléments interactifs) : \n$screenLayout\n. Décris l'écran de manière concise et utile pour une personne malvoyante, en mentionnant les actions possibles.
        """;

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("API Key missing. Please check your .env file.");
      }

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      _lastResponse = response.text ??
          "Désolé, je ne peux pas décrire cet écran pour le moment.";
      await _tts.speak(_sanitizeTextForTts(_lastResponse));
    } catch (e) {
      if (kDebugMode) print("AI Error: $e");
      _lastResponse = "Désolé, l'assistant rencontre une erreur technique.";
      if (e.toString().contains("403")) {
        _lastResponse = "Erreur d'authentification AI. Vérifiez la clé API.";
      }
      await _tts.speak(_lastResponse);
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  Future<void> handleVoiceCommand(String screenContext) async {
    if (kIsWeb) {
      _lastResponse =
          "La commande vocale n'est pas encore supportée sur la version web.";
      await _tts.speak(_lastResponse);
      return;
    }

    _isListening = true;
    notifyListeners();

    await _speech.startListening(
      onResult: (text) async {
        _isListening = false;
        _isThinking = true;
        notifyListeners();

        if (kDebugMode) print('Debug message (command): $screenContext');

        final prompt = """
        Assure que le prompt est toujours en français
        L'utilisateur a dit : '$text'.
        Contexte de l'écran : 
        $screenContext
        
        Les éléments interactifs sont marqués par [id_semantique] (ex: [bouton_rejoindre]).
        Détermine l'intention de l'utilisateur. Répond au format JSON uniquement :
        {
          "intent": "navigation" | "action" | "info",
          "target": "nom de la page ou bouton" (si navigation/info),
          "targetId": "string" (si action, l'ID sémantique de l'élément à cliquer),
          "response": "ce que tu vas dire à l'utilisateur"
        }
        
        Si l'utilisateur veut cliquer sur un bouton, trouve son ID sémantique dans le contexte et utilise intent="action" et targetId="...".
        """;

        try {
          final content = [Content.text(prompt)];
          final response = await _model.generateContent(content);
          final responseText = response.text ?? "{}";

          // Extract JSON from potentially markdown-wrapped response
          final jsonStr = _extractJson(responseText);
          final Map<String, dynamic> result = jsonDecode(jsonStr);

          _lastResponse =
              result['response'] ?? "Je n'ai pas compris la commande.";
          await _tts.speak(_sanitizeTextForTts(_lastResponse));

          if (result['intent'] == 'navigation') {
            _executeNavigation(result['target']);
          } else if (result['intent'] == 'info') {
            await _executeInfo(result['target']);
          } else if (result['intent'] == 'action' &&
              result['targetId'] != null) {
            final String id = result['targetId'].toString();
            if (kDebugMode) print("Assistant executing tap on ID: $id");
            await AccessibilityUtils.simulateTap(id);
          }
        } catch (e) {
          if (kDebugMode) print("AI Command Error: $e");
          await _tts.speak(
              "Une erreur est survenue lors de l'exécution de la commande.");
        } finally {
          _isThinking = false;
          notifyListeners();
        }
      },
      onStatus: (status) {
        if (status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
      onError: (error) {
        _isListening = false;
        notifyListeners();
        if (error.errorMsg == 'error_no_match') {
          _tts.speak("Je n'ai rien entendu. Veuillez réessayer.");
        } else if (error.errorMsg == 'error_speech_timeout') {
          _tts.speak("Je n'ai rien entendu. Le temps d'écoute est écoulé.");
        } else {
          _tts.speak("Erreur de reconnaissance vocale.");
        }
      },
      onSoundLevelChange: (level) {
        _soundLevel = level;
        notifyListeners();
      },
    );
  }

  String _sanitizeTextForTts(String text) {
    // Remove markdown bold/italic/code markers
    return text
            .replaceAll(RegExp(r'[*_`~]'), '') // Remove *, _, `, ~
            .replaceAll(RegExp(r'\[.*?\]'), '') // Remove [links] or [indices]
            .replaceAll(RegExp(r'\(.*?\)'),
                '') // Remove (urls) - maybe too aggressive? Let's just remove empty ones or common markdown patterns
        ;
  }

  String _extractJson(String text) {
    if (text.contains('```json')) {
      final start = text.indexOf('```json') + 7;
      final end = text.lastIndexOf('```');
      return text.substring(start, end).trim();
    }
    // Fallback: try to find the start and end of a JSON object
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1) {
      return text.substring(start, end + 1).trim();
    }
    return text.trim();
  }

  void _executeNavigation(String target) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final lowerTarget = target.toLowerCase();

    if (lowerTarget.contains('accueil') || lowerTarget.contains('home')) {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    } else if (lowerTarget.contains('profil') ||
        lowerTarget.contains('profile')) {
      Navigator.pushNamed(context, '/profile');
    } else if (lowerTarget.contains('événement') ||
        lowerTarget.contains('event')) {
      Navigator.pushNamed(context, '/events'); // Adjust verify route name
    } else if (lowerTarget.contains('notification')) {
      Navigator.pushNamed(context, '/notifications');
    } else if (lowerTarget.contains('utilisateur') ||
        lowerTarget.contains('user')) {
      Navigator.pushNamed(context, '/manage_users');
    } else {
      _tts.speak("Désolé, je ne connais pas cette page.");
    }
  }

  Future<void> _executeInfo(String target) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final lowerTarget = target.toLowerCase();
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (lowerTarget.contains('notification')) {
      if (user == null) {
        _tts.speak("Vous devez être connecté pour lire vos notifications.");
        return;
      }

      final notificationService =
          Provider.of<NotificationService>(context, listen: false);

      final notifications = await notificationService.fetchRecentAnnouncements(
        user.group ?? 'All',
        user.lastReadTimestamp,
      );

      if (notifications.isEmpty) {
        _tts.speak("Vous n'avez aucune nouvelle notification.");
      } else {
        final count = notifications.length;
        _tts.speak(
            "Vous avez $count nouvelles notifications. La plus récente est : ${notifications.first.title}. ${notifications.first.body}");
        // Optionally update last read? Maybe not automatically on voice read yet.
      }
    } else if (lowerTarget.contains('événement') ||
        lowerTarget.contains('prochain')) {
      final eventService = Provider.of<EventService>(context, listen: false);
      // Pass the user's group to filter relevant events
      final events = await eventService.getEvents(group: user?.group ?? 'All');
      final upcoming = events
          .where((e) => e.date.isAfter(DateTime.now()))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (upcoming.isNotEmpty) {
        final next = upcoming.first;
        final dateStr =
            "${next.date.day}/${next.date.month} à ${next.date.hour} heures ${next.date.minute}";
        _tts.speak("Le prochain événement est ${next.title}, le $dateStr.");
      } else {
        _tts.speak("Vous n'avez aucun événement à venir.");
      }
    }
  }
}
