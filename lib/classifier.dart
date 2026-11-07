import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

/// On-device YAMNet (AudioSet, 521 classes) classifier filtered to animal & pet sounds.
/// Note: `yamnet_class_map.csv` must keep all 521 rows intact because YAMNet's output
/// tensor has 521 fixed indices; we filter by allowed class indices in Dart.
class SoundClassifier {
  static const _frame = 15600; // 0.975 s @ 16 kHz, the model's fixed input size.

  /// Allowed YAMNet class indices:
  /// - 67..131: All Animal classes (Dog, Bark, Yip, Howl, Growling, Whimper, Cat, Purr,
  ///   Meow, Hiss, Caterwaul, Horse, Neigh/whinny, Clip-clop, Bird, Chirp/tweet, Squawk, Coo, etc.)
  /// - Shared vocal/breathing cues often triggered by pets:
  ///   21 (Whimper), 22 (Wail/moan), 23 (Sigh), 33 (Groan), 34 (Grunt),
  ///   36 (Breathing), 37 (Wheeze), 38 (Snoring), 39 (Gasp), 40 (Pant),
  ///   41 (Snort), 42 (Cough), 44 (Sneeze), 45 (Sniff), 49 (Chewing), 50 (Biting),
  ///   479 (Squeal)
  static final Set<int> _animalIndices = {
    for (var i = 67; i <= 131; i++) i,
    21, 22, 23, 33, 34, 36, 37, 38, 39, 40, 41, 42, 44, 45, 49, 50, 479,
  };

  /// Species-specific priority indices so we can also surface specific vocalizations
  /// for the selected animal (dog, cat, bird, horse).
  static const Map<String, Set<int>> _speciesIndices = {
    'dog': {67, 68, 69, 70, 71, 72, 73, 74, 75, 117, 21, 33, 34, 40, 41, 45},
    'cat': {67, 68, 76, 77, 78, 79, 80, 104, 105, 21, 22, 36, 40, 45},
    'bird': {67, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116},
    'horse': {67, 81, 82, 83, 84, 33, 34, 36, 40, 41, 45, 479},
  };

  Interpreter? _interp;
  List<String>? _labels;

  Future<void> _load() async {
    if (_interp != null) return;
    _interp = await Interpreter.fromAsset('assets/yamnet/yamnet.tflite');
    final csv = await rootBundle.loadString('assets/yamnet/yamnet_class_map.csv');
    _labels = csv.split('\n').skip(1).where((l) => l.trim().isNotEmpty).map((l) {
      final first = l.indexOf(',');
      final second = l.indexOf(',', first + 1);
      return l.substring(second + 1).trim().replaceAll('"', '');
    }).toList();
  }

  /// Returns filtered animal sound classes e.g. "Dog (0.82); Bark (0.74)"
  /// or null if unavailable / no animal sound detected.
  Future<String?> classify(String audioPath, {String? species}) async {
    try {
      final samples = await _readWav16k(audioPath);
      if (samples == null || samples.length < _frame ~/ 2) return null;
      await _load();

      final interp = _interp!;
      final outLen = _labels!.length;
      final sums = List<double>.filled(outLen, 0);
      var frames = 0;
      // 50% overlap, capped to keep latency low on long clips.
      for (var s = 0; s + _frame <= samples.length && frames < 20; s += _frame ~/ 2) {
        final input = Float32List.sublistView(samples, s, s + _frame);
        final out = List.filled(outLen, 0.0).reshape([1, outLen]);
        interp.run(input.reshape([_frame]), out);
        final row = (out[0] as List).cast<double>();
        for (var i = 0; i < outLen; i++) {
          sums[i] += row[i];
        }
        frames++;
      }
      if (frames == 0) {
        // Clip shorter than one frame: zero-pad.
        final padded = Float32List(_frame)..setAll(0, samples);
        final out = List.filled(outLen, 0.0).reshape([1, outLen]);
        interp.run(padded.reshape([_frame]), out);
        final row = (out[0] as List).cast<double>();
        for (var i = 0; i < outLen; i++) {
          sums[i] = row[i];
        }
        frames = 1;
      }

      // Only rank allowed animal indices (ignoring Speech, Music, Silence, Vehicles, etc.).
      final allowed = (species != null && _speciesIndices.containsKey(species))
          ? {..._speciesIndices[species]!, ..._animalIndices}
          : _animalIndices;

      final idx = allowed.where((i) => i < outLen).toList()
        ..sort((a, b) => sums[b].compareTo(sums[a]));

      final matches = idx
          .where((i) => sums[i] / frames > 0.02)
          .take(4)
          .map((i) => '${_labels![i]} (${(sums[i] / frames).toStringAsFixed(2)})')
          .toList();

      return matches.isEmpty ? 'No clear animal vocalization detected' : matches.join('; ');
    } catch (_) {
      return null; // Classifier is best-effort; Gemini still gets the audio.
    }
  }

  /// Minimal WAV parser: PCM16, mono, 16 kHz only.
  Future<Float32List?> _readWav16k(String path) async {
    if (!path.toLowerCase().endsWith('.wav')) return null;
    final b = (await File(path).readAsBytes());
    final d = ByteData.sublistView(b);
    if (b.length < 44 || String.fromCharCodes(b.sublist(0, 4)) != 'RIFF') return null;
    var pos = 12;
    int? rate, channels, bits;
    while (pos + 8 <= b.length) {
      final id = String.fromCharCodes(b.sublist(pos, pos + 4));
      final size = d.getUint32(pos + 4, Endian.little);
      if (id == 'fmt ') {
        channels = d.getUint16(pos + 10, Endian.little);
        rate = d.getUint32(pos + 12, Endian.little);
        bits = d.getUint16(pos + 22, Endian.little);
      } else if (id == 'data') {
        if (rate != 16000 || channels != 1 || bits != 16) return null;
        final end = (pos + 8 + size).clamp(0, b.length);
        final n = (end - pos - 8) ~/ 2;
        final out = Float32List(n);
        for (var i = 0; i < n; i++) {
          out[i] = d.getInt16(pos + 8 + i * 2, Endian.little) / 32768.0;
        }
        return out;
      }
      pos += 8 + size + (size.isOdd ? 1 : 0);
    }
    return null;
  }
}
