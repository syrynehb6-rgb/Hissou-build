import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/health_record.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/health_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../l10n.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  final _healthRepo = HealthRepository();
  final _petRepo = PetRepository();

  List<HealthReminder> _reminders = [];
  List<Pet> _pets = [];
  bool _sosActive = false;
  bool _loading = true;

  // Interactive Bento Trackers
  int _waterBowls = 3; // out of 4
  int _mealsServed = 2; // out of 3
  final double _petWeight = 4.2; // kg

  late AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final reminders = await _healthRepo.getReminders();
    final pets = await _petRepo.getPets();
    final sos = await _healthRepo.isSosActive();
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _pets = pets;
        _sosActive = sos;
        _loading = false;
      });
    }
  }

  int get _wellnessScore {
    int base = 82;
    base += (_waterBowls * 2);
    base += (_mealsServed * 3);
    final completedCount = _reminders.where((r) => r.isCompleted).length;
    base += (completedCount * 2);
    return base.clamp(75, 100);
  }

  void _showHealthPassportModal(bool isDark) {
    final activePet = _pets.isNotEmpty ? _pets.first.name : 'Milo';
    final activeSpecies = _pets.isNotEmpty ? _pets.first.species : 'cat';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 30, offset: Offset(0, -10)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Passport Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HissouColors.primaryNavy, Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: HissouColors.primaryNavy.withAlpha(80),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [HissouColors.accentAmber, HissouColors.softRose],
                            ),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.pets_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'PASSEPORT SANITAIRE',
                                    style: TextStyle(
                                      color: HissouColors.accentAmber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, color: HissouColors.successGreen, size: 14),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activePet,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Espèce: ${activeSpecies.toUpperCase()} • Poids: ${_petWeight.toStringAsFixed(1)} kg',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            color: HissouColors.primaryNavy,
                            size: 38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'N° Puce ISO : 981020000482910',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Groupe Sanguin : A+',
                            style: TextStyle(
                              color: HissouColors.accentAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Certificats de Vaccination Officiels',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : HissouColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildVaccineStamp('Vaccin Antirabique', 'Valide 2027', HissouColors.successGreen, isDark),
                  _buildVaccineStamp('Typhus & Coryza (RCP)', 'À jour ✓', HissouColors.successGreen, isDark),
                  _buildVaccineStamp('Leucose Féline (FeLV)', 'À jour ✓', HissouColors.accentAmberDark, isDark),
                  _buildVaccineStamp('Vermifuge Interne', 'Fait il y a 14j', HissouColors.warmPlum, isDark),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✓ Passeport Sanitaire exporté et prêt à partager avec votre vétérinaire !'),
                        backgroundColor: HissouColors.successGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HissouColors.accentAmber,
                    foregroundColor: HissouColors.primaryNavyDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Partager / Exporter au Vétérinaire',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaccineStamp(String title, String status, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, size: 15, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : HissouColors.primaryNavy,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog() {
    final titleCtl = TextEditingController();
    final notesCtl = TextEditingController();
    ReminderType type = ReminderType.vaccine;
    Pet? selectedPet = _pets.isNotEmpty ? _pets.first : null;

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
                const SizedBox(height: 18),
                Text(
                  tr(context, 'add_reminder'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : HissouColors.primaryNavy,
                      ),
                ),
                const SizedBox(height: 14),
                if (_pets.isNotEmpty)
                  DropdownButtonFormField<Pet>(
                    initialValue: selectedPet,
                    decoration: InputDecoration(
                      labelText: tr(context, 'name'),
                      prefixIcon: const Icon(Icons.pets_rounded, color: HissouColors.accentAmber),
                    ),
                    items: _pets.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.name));
                    }).toList(),
                    onChanged: (p) => setDialogState(() => selectedPet = p),
                  ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ReminderType.values.map((t) {
                      final isSelected = type == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(tr(context, t.name)),
                          selected: isSelected,
                          onSelected: (_) => setDialogState(() => type = t),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtl,
                  decoration: InputDecoration(
                    labelText: tr(context, 'listing_title'),
                    prefixIcon: const Icon(Icons.event_note_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtl,
                  decoration: InputDecoration(
                    labelText: tr(context, 'context'),
                    prefixIcon: const Icon(Icons.notes_rounded),
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
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HissouColors.accentAmber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: () async {
                        final title = titleCtl.text.trim();
                        if (title.isEmpty) return;
                        final reminder = HealthReminder(
                          id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
                          petId: selectedPet?.id ?? '',
                          petName: selectedPet?.name ?? 'My Pet',
                          title: title,
                          type: type,
                          dueDate: DateTime.now().add(const Duration(days: 7)),
                          notes: notesCtl.text.trim(),
                        );
                        await _healthRepo.addReminder(reminder);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadData();
                      },
                      child: Text(tr(context, 'save')),
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

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.vaccine:
        return Icons.vaccines_rounded;
      case ReminderType.vet:
        return Icons.medical_services_rounded;
      case ReminderType.deworming:
        return Icons.healing_rounded;
      case ReminderType.grooming:
        return Icons.content_cut_rounded;
    }
  }

  Color _getTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.vaccine:
        return HissouColors.softRose;
      case ReminderType.vet:
        return HissouColors.primaryNavy;
      case ReminderType.deworming:
        return HissouColors.accentAmberDark;
      case ReminderType.grooming:
        return HissouColors.warmPlum;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = _wellnessScore;

    return ResponsiveLayout.constrainedContainer(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: HissouColors.accentAmber,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'health_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -0.6,
                          color: isDark ? Colors.white : HissouColors.primaryNavy,
                        ),
                      ),
                      const Text(
                        'Tableau de Bord Biométrique & Suivi Vétérinaire',
                        style: TextStyle(
                          fontSize: 12,
                          color: HissouColors.neutralGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                BouncyTap(
                  onTap: () => _showHealthPassportModal(isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [HissouColors.accentAmber, HissouColors.softRose],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: HissouColors.accentAmber.withAlpha(60),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Passeport ID',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // BENTO HERO TILE (2x1 Span): Animated Circular Vitality Score & Biometrics
            _buildBentoWellnessHero(score, isDark),

            const SizedBox(height: 12),

            // BENTO 2-COLUMN SECONDARY TILES (1x1 Spans): Hydration & Nutrition Trackers
            Row(
              children: [
                Expanded(
                  child: _buildBentoHydrationTile(isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoNutritionTile(isDark),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // SOS Radar Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: _sosActive
                      ? [HissouColors.errorRed, const Color(0xFFC0392B)]
                      : [const Color(0xFF172C4F), const Color(0xFF244477)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_sosActive ? HissouColors.errorRed : HissouColors.primaryNavy).withAlpha(60),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _sosActive ? Icons.warning_amber_rounded : Icons.radar_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sosActive ? tr(context, 'sos_active') : tr(context, 'sos_radar'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(context, 'sos_desc'),
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _sosActive,
                    activeThumbColor: HissouColors.accentAmber,
                    activeTrackColor: Colors.white24,
                    onChanged: (val) async {
                      HapticFeedback.mediumImpact();
                      await _healthRepo.setSosActive(val);
                      if (!context.mounted) return;
                      setState(() => _sosActive = val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val
                              ? '🚨 Alerte SOS activée : la communauté Hissou à proximité est notifiée !'
                              : 'Alerte SOS désactivée.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Reminders Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tr(context, 'reminders'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: isDark ? Colors.white : HissouColors.primaryNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _showAddReminderDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(tr(context, 'add_reminder')),
                  style: TextButton.styleFrom(
                    foregroundColor: HissouColors.accentAmberDark,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (_loading)
              const Center(child: CircularProgressIndicator(color: HissouColors.accentAmber))
            else if (_reminders.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : HissouColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Icon(Icons.health_and_safety_outlined, size: 44, color: Colors.grey.withAlpha(120)),
                    const SizedBox(height: 10),
                    Text(
                      tr(context, 'empty_reminders'),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : HissouColors.neutralGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final rem in _reminders)
                _buildReminderCard(rem, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoWellnessHero(int score, bool isDark) {
    final activePet = _pets.isNotEmpty ? _pets.first.name : 'Milo';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white12 : HissouColors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: HissouColors.primaryNavy.withAlpha(isDark ? 45 : 12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Circular Wellness Ring
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: score / 100.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, val, _) {
              return SizedBox(
                width: 86,
                height: 86,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: val,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(HissouColors.successGreen),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(val * 100).round()}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : HissouColors.primaryNavy,
                            ),
                          ),
                          const Text(
                            'VITALITÉ',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: HissouColors.successGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: HissouColors.successGreen.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded, size: 12, color: HissouColors.successGreen),
                          SizedBox(width: 4),
                          Text(
                            'Santé Optimale',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: HissouColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _heartController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_heartController.value * 0.18),
                          child: child,
                        );
                      },
                      child: const Icon(Icons.favorite_rounded, color: HissouColors.softRose, size: 18),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '128 BPM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : HissouColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bilan de $activePet aujourd\'hui',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : HissouColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Poids stable (${_petWeight.toStringAsFixed(1)} kg) • Sommeil réparateur • Humeur joyeuse détectée par l\'IA.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark ? Colors.white70 : HissouColors.neutralGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoHydrationTile(bool isDark) {
    final progress = (_waterBowls / 4.0).clamp(0.0, 1.0);
    return BouncyTap(
      onTap: () {
        setState(() {
          _waterBowls = (_waterBowls % 5) + 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? Colors.white12 : HissouColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+ Ajouter',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$_waterBowls / 4 Bols',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : HissouColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Hydratation (${_waterBowls * 65} ml)',
              style: const TextStyle(fontSize: 11, color: HissouColors.neutralGrey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoNutritionTile(bool isDark) {
    final progress = (_mealsServed / 3.0).clamp(0.0, 1.0);
    return BouncyTap(
      onTap: () {
        setState(() {
          _mealsServed = (_mealsServed % 4) + 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? Colors.white12 : HissouColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HissouColors.accentAmber.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: HissouColors.accentAmberDark, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: HissouColors.accentAmber.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+ Repas',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: HissouColors.accentAmberDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$_mealsServed / 3 Repas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : HissouColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Calories (${_mealsServed * 85} kcal)',
              style: const TextStyle(fontSize: 11, color: HissouColors.neutralGrey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(HissouColors.accentAmber),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(HealthReminder rem, bool isDark) {
    final typeColor = _getTypeColor(rem.type);
    final daysUntil = rem.dueDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? HissouColors.cardSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : HissouColors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: HissouColors.primaryNavy.withAlpha(isDark ? 30 : 8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_getTypeIcon(rem.type), color: typeColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rem.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            decoration: rem.isCompleted ? TextDecoration.lineThrough : null,
                            color: rem.isCompleted
                                ? Colors.grey
                                : (isDark ? Colors.white : HissouColors.primaryNavy),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: HissouColors.primaryNavy.withAlpha(isDark ? 80 : 15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rem.petName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : HissouColors.primaryNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rem.notes.isNotEmpty ? rem.notes : tr(context, rem.type.name),
                    style: const TextStyle(fontSize: 12, color: HissouColors.neutralGrey),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (daysUntil < 3 ? HissouColors.errorRed : HissouColors.accentAmber)
                          .withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      daysUntil >= 0 ? 'Dans $daysUntil jours' : 'En retard',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: daysUntil < 3 ? HissouColors.errorRed : HissouColors.accentAmberDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: rem.isCompleted,
              activeColor: HissouColors.successGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: (v) async {
                HapticFeedback.lightImpact();
                await _healthRepo.toggleCompleted(rem.id);
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }
}
