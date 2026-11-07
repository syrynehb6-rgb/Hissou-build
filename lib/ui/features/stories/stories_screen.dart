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
                  value: selectedPet,
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

                  // Existing Pets Stories
                  for (final p in _pets)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
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
                                  color: HissouColors.primaryNavy,
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

  Widget _buildStoryCard(StoryPost story, bool isDark) {
    return Container(
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
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: HissouColors.neutralGrey),
                        SizedBox(width: 5),
                        Text(
                          'Reply',
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
                        content: Text('Sharing ${story.petName}\'s story...'),
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
    );
  }
}
