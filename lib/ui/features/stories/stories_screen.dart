import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/story.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/story_repository.dart';
import '../../../l10n.dart';
import '../pets/pet_dialog.dart';

class StoriesScreen extends StatefulWidget {
  final VoidCallback onNavigateToTranslator;

  const StoriesScreen({super.key, required this.onNavigateToTranslator});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final _storyRepo = StoryRepository();
  final _petRepo = PetRepository();

  List<StoryPost> _stories = [];
  List<Pet> _pets = [];
  bool _loading = true;
  String _selectedFilter = 'all'; // all, dog, cat, audio

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final pets = await _petRepo.getPets();
    final stories = await _storyRepo.getStories();
    if (mounted) {
      setState(() {
        _pets = pets;
        _stories = stories;
        _loading = false;
      });
    }
  }

  void _showAddStoryDialog() {
    if (_pets.isEmpty) {
      _showAddPetDialog();
      return;
    }

    final captionCtl = TextEditingController();
    Pet selectedPet = _pets.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            decoration: BoxDecoration(
              color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.withAlpha(90),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  tr(context, 'add_story'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : HissouColors.primaryNavy,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Pet>(
                  initialValue: selectedPet,
                  decoration: InputDecoration(
                    labelText: tr(context, 'species'),
                    prefixIcon: const Icon(Icons.pets_rounded, color: HissouColors.accentAmber),
                  ),
                  items: _pets.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (${tr(context, p.species)})'),
                    );
                  }).toList(),
                  onChanged: (p) {
                    if (p != null) setDialogState(() => selectedPet = p);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: captionCtl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: tr(context, 'story_hint'),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(tr(context, 'cancel')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HissouColors.accentAmber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: () async {
                        final text = captionCtl.text.trim();
                        if (text.isEmpty) return;
                        final newStory = StoryPost(
                          id: 'story_${DateTime.now().millisecondsSinceEpoch}',
                          petId: selectedPet.id,
                          petName: selectedPet.name,
                          species: selectedPet.species,
                          caption: text,
                        );
                        await _storyRepo.addStory(newStory);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadData();
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(tr(context, 'share_story')),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddPetDialog() {
    showDialog(
      context: context,
      builder: (_) => PetDialog(
        onSaved: (newPet) async {
          await _petRepo.addPet(newPet);
          _loadData();
        },
      ),
    );
  }

  IconData _getSpeciesIcon(String species) {
    switch (species.toLowerCase()) {
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

  List<StoryPost> get _filteredStories {
    if (_selectedFilter == 'all') return _stories;
    if (_selectedFilter == 'audio') {
      return _stories.where((s) => s.interpretation != null).toList();
    }
    return _stories.where((s) => s.species.toLowerCase() == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: HissouColors.accentAmber));
    }

    return ResponsiveLayout.constrainedContainer(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: HissouColors.accentAmber,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            // Instagram-grade Pet Stories Reel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tr(context, 'stories_title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : HissouColors.primaryNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _showAddPetDialog,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: Text(tr(context, 'add_pet')),
                  style: TextButton.styleFrom(
                    foregroundColor: HissouColors.accentAmberDark,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stories Carousel
            SizedBox(
              height: 104,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  // Add Story Circle
                  GestureDetector(
                    onTap: _showAddStoryDialog,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Column(
                        children: [
                          Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
                              border: Border.all(
                                color: HissouColors.accentAmber,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: HissouColors.accentAmber.withAlpha(40),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.add_rounded, color: HissouColors.accentAmber, size: 30),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr(context, 'add_story'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : HissouColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Existing Pets Stories (Interactive Fullscreen Viewer)
                  for (final p in _pets)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: BouncyTap(
                        onTap: () => _openStoryViewer(p),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [HissouColors.accentAmber, HissouColors.softRose, HissouColors.warmPlum],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: HissouColors.accentAmber.withAlpha(60),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
                                ),
                                child: Center(
                                  child: Icon(
                                    _getSpeciesIcon(p.species),
                                    color: isDark ? Colors.white : HissouColors.primaryNavy,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Filter Pills Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', tr(context, 'all'), Icons.grid_view_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('dog', tr(context, 'dog'), Icons.pets_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('cat', tr(context, 'cat'), Icons.cruelty_free_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('audio', 'Voice Translations 🎙️', Icons.record_voice_over_rounded, isDark),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // AI Voice Translator Hero CTA
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [HissouColors.primaryNavy, Color(0xFF254B8C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: HissouColors.primaryNavy.withAlpha(50),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: HissouColors.accentAmber.withAlpha(220),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Translate Pet Voice',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Record pet sound & decode their thoughts',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: HissouColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: widget.onNavigateToTranslator,
                    child: const Text('Try Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stories Feed
            if (_filteredStories.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white12 : HissouColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 48, color: Colors.grey.withAlpha(120)),
                    const SizedBox(height: 12),
                    Text(
                      tr(context, 'empty_stories'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : HissouColors.neutralGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final story in _filteredStories)
                _buildStoryCard(story, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon, bool isDark) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? HissouColors.accentAmber : HissouColors.primaryNavy)
              : (isDark ? HissouColors.cardSurfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white12 : HissouColors.borderSubtle),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: HissouColors.primaryNavy.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : HissouColors.neutralGrey),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : HissouColors.primaryNavy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _heartBurstStoryId;

  Future<void> _triggerHeartBurst(StoryPost story) async {
    setState(() => _heartBurstStoryId = story.id);
    if (!story.isLiked) {
      await _storyRepo.toggleLike(story.id);
      final updated = await _storyRepo.getStories();
      if (mounted) setState(() => _stories = updated);
    }
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _heartBurstStoryId = null);
    }
  }

  void _openStoryViewer(Pet pet) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Story Viewer',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) {
        return Scaffold(
          backgroundColor: HissouColors.primaryNavyDark,
          body: SafeArea(
            child: Stack(
              children: [
                // Background Ambient Gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        HissouColors.primaryNavyDark,
                        Color(0xFF1E1B4B),
                        Color(0xFF31102F),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Top Progress Bar & Pet Header
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 5),
                        onEnd: () {
                          if (ctx.mounted && Navigator.of(ctx).canPop()) {
                            Navigator.of(ctx).pop();
                          }
                        },
                        builder: (context, value, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 4,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(HissouColors.accentAmber),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [HissouColors.accentAmber, HissouColors.softRose],
                              ),
                            ),
                            child: Icon(_getSpeciesIcon(pet.species), color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pet.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${pet.breed.isNotEmpty ? pet.breed : pet.species.toUpperCase()} • En direct',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Center Story Content
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(18),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [HissouColors.accentAmber, HissouColors.softRose],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: HissouColors.accentAmber.withAlpha(90),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(_getSpeciesIcon(pet.species), color: Colors.white, size: 48),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: HissouColors.accentAmber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'HUMEUR DÉTECTÉE : JOYEUX & JOUEUR ✨',
                              style: TextStyle(
                                color: HissouColors.primaryNavyDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '“Bonjour ! C\'est ${pet.name}, j\'ai fait ma sieste au soleil et j\'attends mes croquettes avec impatience !”',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Bottom Emoji Quick Reactions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['❤️', '😍', '🐾', '🔥', '👑'].map((emoji) {
                          return BouncyTap(
                            onTap: () {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Réaction $emoji envoyée à ${pet.name} !'),
                                  backgroundColor: HissouColors.primaryNavy,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 22)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  void _showCommentsSheet(StoryPost story, bool isDark) {
    final commentCtl = TextEditingController();
    final comments = <Map<String, String>>[
      {'author': 'Dr. Amine (Vétérinaire)', 'text': 'Trop mignon ! Son miaulement montre qu\'il est en pleine forme 🐾', 'time': 'Il y a 15m'},
      {'author': 'Yasmine & Luna', 'text': 'Adorables ! Ma chatte fait exactement le même bruit devant sa gamelle 😍', 'time': 'Il y a 8m'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Commentaires sur ${story.petName}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : HissouColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 12),
                ...comments.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(8) : HissouColors.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                c['author']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: isDark ? HissouColors.accentAmber : HissouColors.primaryNavy,
                                ),
                              ),
                              Text(
                                c['time']!,
                                style: const TextStyle(fontSize: 10, color: HissouColors.neutralGrey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c['text']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtl,
                        decoration: const InputDecoration(
                          hintText: 'Écrire un commentaire bienveillant...',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: HissouColors.accentAmber),
                      onPressed: () {
                        final text = commentCtl.text.trim();
                        if (text.isEmpty) return;
                        setSheetState(() {
                          comments.add({
                            'author': 'Vous ✨',
                            'text': text,
                            'time': 'À l\'instant',
                          });
                          commentCtl.clear();
                        });
                      },
                      icon: const Icon(Icons.send_rounded, size: 18, color: HissouColors.primaryNavyDark),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoryCard(StoryPost story, bool isDark) {
    final isBursting = _heartBurstStoryId == story.id;
    return GestureDetector(
      onDoubleTap: () => _triggerHeartBurst(story),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white12 : HissouColors.borderSubtle,
              ),
              boxShadow: [
                BoxShadow(
                  color: HissouColors.primaryNavy.withAlpha(isDark ? 40 : 10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Pet Avatar, Name, Species, Time
                  Row(
                    children: [
                      Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [HissouColors.accentAmber, HissouColors.softRose],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getSpeciesIcon(story.species),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            story.petName,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: isDark ? Colors.white : HissouColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: HissouColors.softRose.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tr(context, story.species),
                              style: const TextStyle(
                                fontSize: 10,
                                color: HissouColors.softRose,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateTime.now().difference(story.createdAt).inHours}h ago',
                        style: const TextStyle(
                          fontSize: 11,
                          color: HissouColors.neutralGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, size: 20),
                  color: HissouColors.neutralGrey,
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Caption
            Text(
              story.caption,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark ? Colors.white.withAlpha(230) : const Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),

            // Attached Voice Translation Card
            if (story.interpretation != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HissouColors.accentAmber.withAlpha(isDark ? 40 : 25),
                      HissouColors.softRose.withAlpha(isDark ? 30 : 15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: HissouColors.accentAmber.withAlpha(70),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: HissouColors.accentAmber,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: HissouColors.accentAmber.withAlpha(70),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"${story.interpretation!.message}"',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? Colors.white : HissouColors.primaryNavy,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: HissouColors.accentAmber.withAlpha(40),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  story.interpretation!.mood.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: HissouColors.accentAmberDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(story.interpretation!.confidence * 100).round()}% match',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: HissouColors.neutralGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: isDark ? Colors.white10 : HissouColors.borderSubtle,
            ),
            const SizedBox(height: 8),

            // Action row: Like, Comments, Share
            Row(
              children: [
                InkWell(
                  onTap: () async {
                    await _storyRepo.toggleLike(story.id);
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: story.isLiked ? 1.2 : 1.0,
                          child: Icon(
                            story.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: story.isLiked ? HissouColors.softRose : HissouColors.neutralGrey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${story.likes} ${tr(context, 'likes')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: story.isLiked ? HissouColors.softRose : HissouColors.neutralGrey,
                            fontWeight: story.isLiked ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _showCommentsSheet(story, isDark),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: HissouColors.neutralGrey),
                        SizedBox(width: 5),
                        Text(
                          'Commenter (2)',
                          style: TextStyle(fontSize: 12, color: HissouColors.neutralGrey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 19, color: HissouColors.neutralGrey),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Partage de la story de ${story.petName}...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
          // Floating Heart Burst Overlay on Double-Tap
          IgnorePointer(
            child: AnimatedScale(
              scale: isBursting ? 1.3 : 0.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.elasticOut,
              child: AnimatedOpacity(
                opacity: isBursting ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: HissouColors.softRose.withAlpha(100),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: HissouColors.softRose,
                    size: 54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
