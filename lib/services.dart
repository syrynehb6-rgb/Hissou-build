import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'classifier.dart';

/// Backend proxy URL. 10.0.2.2 reaches the host machine from the Android emulator.
/// Override with: --dart-define=API_URL=https://your-service.run.app
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

class Interpretation {
  final String mood, message, advice, species, petName, language;
  final double confidence;
  final DateTime at;

  Interpretation({
    required this.mood,
    required this.message,
    required this.advice,
    required this.confidence,
    required this.species,
    required this.petName,
    required this.language,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'mood': mood,
        'message': message,
        'advice': advice,
        'confidence': confidence,
        'species': species,
        'petName': petName,
        'language': language,
        'at': at.toIso8601String(),
      };

  factory Interpretation.fromJson(Map<String, dynamic> j) => Interpretation(
        mood: '${j['mood'] ?? ''}',
        message: '${j['message'] ?? ''}',
        advice: '${j['advice'] ?? ''}',
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
        species: '${j['species'] ?? ''}',
        petName: '${j['petName'] ?? ''}',
        language: '${j['language'] ?? 'en'}',
        at: DateTime.tryParse('${j['at']}'),
      );
}

class InterpretService {
  final _classifier = SoundClassifier();

  Future<Interpretation> interpret({
    required String audioPath,
    required String species,
    required String petName,
    required String context,
    required String language,
  }) async {
    final bytes = await File(audioPath).readAsBytes();
    final soundClass = await _classifier.classify(audioPath, species: species);
    final mime = audioPath.toLowerCase().endsWith('.mp3')
        ? 'audio/mp3'
        : audioPath.toLowerCase().endsWith('.wav')
            ? 'audio/wav'
            : 'audio/mp4';

    final res = await http
        .post(
          Uri.parse('$apiUrl/interpret'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'audioBase64': base64Encode(bytes),
            'mimeType': mime,
            'species': species,
            'name': petName,
            'context': context,
            'language': language,
            'soundClass': soundClass,
          }),
        )
        .timeout(const Duration(seconds: 60));

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(body['error'] ?? 'HTTP ${res.statusCode}');
    body['species'] = species;
    body['petName'] = petName;
    body['language'] = language;
    return Interpretation.fromJson(body);
  }
}

class HistoryStore {
  static const _key = 'history';

  Future<List<Interpretation>> load() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key) ?? [])
        .map((s) => Interpretation.fromJson(jsonDecode(s)))
        .toList();
  }

  Future<void> add(Interpretation i) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? [];
    list.insert(0, jsonEncode(i.toJson()));
    await p.setStringList(_key, list.take(100).toList());
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
