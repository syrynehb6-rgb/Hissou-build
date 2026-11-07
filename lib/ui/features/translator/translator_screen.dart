import 'dart:async';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/story.dart';
import '../../../data/repositories/story_repository.dart';
import '../../../l10n.dart';
import '../../../services.dart';

class TranslatorScreen extends StatefulWidget {
  final VoidCallback onStoryShared;

  const TranslatorScreen({super.key, required this.onStoryShared});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with TickerProviderStateMixin {
  final _recorder = AudioRecorder();
  final _tts = FlutterTts();
  final _service = InterpretService();
  final _store = HistoryStore();
  final _storyRepo = StoryRepository();

  final _nameCtl = TextEditingController();
  final _ctxCtl = TextEditingController();

  String _species = 'dog';
  bool _recording = false;
  bool _busy = false;
  Interpretation? _result;
  List<Interpretation> _history = [];

  late AnimationController _pulseController;
  late AnimationController _waveController;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  final List<Map<String, String>> _quickContexts = [
    {'emoji': '🍗', 'en': 'Hungry / Feeding', 'fr': 'Affamé / Repas', 'ar': 'جائع / وجبة'},
    {'emoji': '🎾', 'en': 'Playing / Excited', 'fr': 'Joueur / Excité', 'ar': 'مرح / نشيط'},
    {'emoji': '🚪', 'en': 'At the door', 'fr': 'À la porte', 'ar': 'عند الباب'},
    {'emoji': '😴', 'en': 'Sleepy / Waking', 'fr': 'Somnolent', 'ar': 'نعسان'},
    {'emoji': '❤️', 'en': 'Seeking attention', 'fr': 'Câlin / Attention', 'ar': 'يريد اهتمام'},
    {'emoji': '⚠️', 'en': 'Alert / Guarding', 'fr': 'Alerte / Garde', 'ar': 'حذر / حراسة'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _store.load().then((h) {
      if (mounted) setState(() => _history = h);
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _tts.stop();
    _recordTimer?.cancel();
    _nameCtl.dispose();
    _ctxCtl.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _toggleRecord() async {
    if (_busy) return;
    if (_recording) {
      _recordTimer?.cancel();
      final path = await _recorder.stop();
      _pulseController.stop();
      _pulseController.reset();
      _waveController.stop();
      _waveController.reset();
      setState(() {
        _recording = false;
        _recordSeconds = 0;
      });
      if (path != null) await _analyze(path);
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (mounted) _snack(tr(context, 'mic'));
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/clip_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: path,
    );
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    setState(() {
      _recording = true;
      _recordSeconds = 0;
    });

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _recording) {
        setState(() => _recordSeconds++);
        if (_recordSeconds >= 30) {
          _toggleRecord();
        }
      }
    });
  }

  Future<void> _pickFile() async {
    if (_busy || _recording) return;
    final r = await FilePicker.pickFiles(type: FileType.audio);
    final path = r?.files.single.path;
    if (path != null) await _analyze(path);
  }

  Future<void> _analyze(String path) async {
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final res = await _service.interpret(
        audioPath: path,
        species: _species,
        petName: _nameCtl.text.trim(),
        context: _ctxCtl.text.trim(),
        language: lang,
      );
      await _store.add(res);
      final h = await _store.load();
      if (!mounted) return;
      setState(() {
        _result = res;
        _history = h;
      });
      await _speak(res);
    } catch (e) {
      if (mounted) _snack('${tr(context, 'error')}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _speak(Interpretation i) async {
    const tags = {'en': 'en-US', 'fr': 'fr-FR', 'ar': 'ar-SA'};
    await _tts.setLanguage(tags[i.language] ?? 'en-US');
    await _tts.speak(i.message);
  }

  Future<void> _shareToStory(Interpretation res) async {
    final petName = res.petName.isNotEmpty ? res.petName : 'My Pet';
    final story = StoryPost(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      petId: 'pet_trans_${DateTime.now().millisecondsSinceEpoch}',
      petName: petName,
      species: res.species,
      caption: 'Look what $petName is saying today! Mood: ${res.mood}.',
      interpretation: res,
    );
    await _storyRepo.addStory(story);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Posted $petName\'s voice interpretation to Pet Chronicles!'),
          backgroundColor: HissouColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      widget.onStoryShared();
    }
  }

  IconData _getSpeciesIcon(String s) {
    switch (s) {
      case 'cat':
        return Icons.cruelty_free_rounded;
      case 'bird':
        return Icons.flutter_dash_rounded;
      case 'horse':
        return Icons.agriculture_rounded;
      case 'dog':
      default:
        return Icons.pets_rounded;
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;

    return ResponsiveLayout.constrainedContainer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Header Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [HissouColors.cardSurfaceDark, const Color(0xFF1E3A6B)]
                    : [const Color(0xFF172C4F), const Color(0xFF254B8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: HissouColors.primaryNavy.withAlpha(40),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: HissouColors.accentAmber.withAlpha(220),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'YAMNet AI Neural Audio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tr(context, 'nav_translator'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(context, 'tagline'),
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(25),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: HissouColors.accentAmber,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Animal species selection cards
          Row(
            children: [
              for (final s in ['dog', 'cat', 'bird', 'horse']) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _species = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _species == s
                            ? (_species == 'dog'
                                ? HissouColors.accentAmber
                                : _species == 'cat'
                                    ? HissouColors.softRose
                                    : HissouColors.primaryNavy)
                            : (isDark ? HissouColors.cardSurfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _species == s
                              ? Colors.transparent
                              : (isDark ? Colors.white12 : HissouColors.borderSubtle),
                          width: 1.5,
                        ),
                        boxShadow: _species == s
                            ? [
                                BoxShadow(
                                  color: (_species == 'dog'
                                          ? HissouColors.accentAmber
                                          : HissouColors.softRose)
                                      .withAlpha(80),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSpeciesIcon(s),
                            size: 24,
                            color: _species == s
                                ? Colors.white
                                : (isDark ? Colors.white70 : HissouColors.primaryNavy),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(context, s),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _species == s ? FontWeight.w800 : FontWeight.w600,
                              color: _species == s
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : HissouColors.primaryNavy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (s != 'horse') const SizedBox(width: 8),
              ],
            ],
          ),

          const SizedBox(height: 18),

          // Situation / Context tags
          Text(
            tr(context, 'context'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : HissouColors.neutralGrey,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickContexts.map((ctxItem) {
                final text = ctxItem[lang] ?? ctxItem['en']!;
                final isSelected = _ctxCtl.text == text;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Text(ctxItem['emoji']!, style: const TextStyle(fontSize: 13)),
                    label: Text(text),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _ctxCtl.text = val ? text : '';
                      });
                    },
                    selectedColor: HissouColors.accentAmber.withAlpha(40),
                    backgroundColor: isDark ? HissouColors.cardSurfaceDark : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected
                            ? HissouColors.accentAmber
                            : (isDark ? Colors.white12 : HissouColors.borderSubtle),
                      ),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? HissouColors.accentAmber : HissouColors.accentAmberDark)
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Optional Inputs Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: tr(context, 'name'),
                    prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctxCtl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: tr(context, 'context'),
                    prefixIcon: const Icon(Icons.psychology_outlined, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Central Hero Studio Stage
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _recording
                    ? HissouColors.errorRed.withAlpha(80)
                    : (isDark ? Colors.white12 : HissouColors.borderSubtle),
                width: _recording ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: HissouColors.primaryNavy.withAlpha(isDark ? 50 : 15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Live Soundwave Bars
                SizedBox(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(16, (index) {
                      return AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, _) {
                          final wave = sin((index * 0.4) + (_waveController.value * 2 * pi));
                          final activeHeight = _recording
                              ? 10.0 + (wave.abs() * 26.0)
                              : 6.0 + (sin(index * 0.5).abs() * 6.0);

                          return Container(
                            width: 4,
                            height: activeHeight,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _recording
                                  ? HissouColors.errorRed
                                  : (_busy
                                      ? HissouColors.accentAmber
                                      : HissouColors.primaryNavy.withAlpha(isDark ? 80 : 35)),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 20),

                // Record Button with Ripple Halo
                Center(
                  child: Semantics(
                    button: true,
                    label: tr(context, _recording ? 'stop' : 'record'),
                    child: GestureDetector(
                      onTap: _toggleRecord,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulse = _pulseController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_recording) ...[
                                Container(
                                  width: 140 + (pulse * 30),
                                  height: 140 + (pulse * 30),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: HissouColors.errorRed.withAlpha((70 * (1 - pulse)).toInt()),
                                  ),
                                ),
                                Container(
                                  width: 120 + (pulse * 15),
                                  height: 120 + (pulse * 15),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: HissouColors.errorRed.withAlpha((100 * (1 - pulse)).toInt()),
                                  ),
                                ),
                              ],
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _recording
                                        ? [HissouColors.errorRed, const Color(0xFFC0392B)]
                                        : [HissouColors.accentAmber, const Color(0xFFE58712)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_recording ? HissouColors.errorRed : HissouColors.accentAmber)
                                          .withAlpha(100),
                                      blurRadius: _recording ? 24 : 14,
                                      spreadRadius: _recording ? 4 : 2,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _recording ? Icons.stop_rounded : Icons.mic_rounded,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Timer & State Label
                Text(
                  _recording
                      ? 'Recording ${_formatTime(_recordSeconds)} / 00:30'
                      : tr(context, 'record'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _recording
                        ? HissouColors.errorRed
                        : (isDark ? Colors.white : HissouColors.primaryNavy),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _recording ? 'Listening closely to your pet...' : 'Tap to start recording or upload an audio clip',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : HissouColors.neutralGrey,
                  ),
                ),

                const SizedBox(height: 14),

                // Upload Audio Action
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(tr(context, 'upload')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : HissouColors.primaryNavy,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : HissouColors.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),

          if (_busy) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HissouColors.accentAmber.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: HissouColors.accentAmber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'analyzing'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Deconstructing sound frequencies & pet mood patterns...',
                          style: TextStyle(fontSize: 11, color: HissouColors.neutralGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(_result!, isDark),
          ],

          const SizedBox(height: 20),

          Center(
            child: Text(
              tr(context, 'disclaimer'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : HissouColors.neutralGrey,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sound History Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'history'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: isDark ? Colors.white : HissouColors.primaryNavy,
                ),
              ),
              if (_history.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: HissouColors.accentAmber.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_history.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: HissouColors.accentAmberDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_history.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white12 : HissouColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.history_edu_rounded,
                    size: 40,
                    color: isDark ? Colors.white30 : Colors.grey.withAlpha(120),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(context, 'empty'),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : HissouColors.neutralGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final i in _history)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.white12 : HissouColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: HissouColors.primaryNavy.withAlpha(isDark ? 30 : 8),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: HissouColors.accentAmber.withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_getSpeciesIcon(i.species), color: HissouColors.accentAmber, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? Colors.white : HissouColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${i.species.toUpperCase()} • ${i.mood}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: HissouColors.neutralGrey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: HissouColors.neutralGrey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(i.confidence * 100).round()}% match',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: HissouColors.successGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: HissouColors.primaryNavy.withAlpha(isDark ? 80 : 15),
                        foregroundColor: isDark ? Colors.white : HissouColors.primaryNavy,
                      ),
                      onPressed: () => _speak(i),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Interpretation i, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: HissouColors.accentAmber,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: HissouColors.accentAmber.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HissouColors.accentAmber.withAlpha(isDark ? 60 : 35),
                  HissouColors.softRose.withAlpha(isDark ? 60 : 35),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: HissouColors.accentAmber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    i.mood.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(i.confidence * 100).round()}% match confidence',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : HissouColors.neutralGrey,
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: HissouColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _speak(i),
                  icon: const Icon(Icons.volume_up_rounded, size: 16),
                  label: Text(tr(context, 'listen'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Speech Bubble
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(10)
                        : HissouColors.backgroundLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white10 : HissouColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '“',
                        style: TextStyle(
                          fontSize: 32,
                          height: 0.8,
                          fontWeight: FontWeight.bold,
                          color: HissouColors.accentAmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          i.message,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                            color: isDark ? Colors.white : HissouColors.primaryNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (i.advice.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HissouColors.accentAmber.withAlpha(15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: HissouColors.accentAmber.withAlpha(40)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          size: 18,
                          color: HissouColors.accentAmberDark,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(context, 'advice'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: HissouColors.accentAmberDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                i.advice,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Share Button with gradient
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [HissouColors.primaryNavy, Color(0xFF23447A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: HissouColors.primaryNavy.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _shareToStory(i),
                      icon: const Icon(Icons.auto_stories_rounded, size: 18, color: Colors.white),
                      label: Text(
                        tr(context, 'share_to_story'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
