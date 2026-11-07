import 'package:flutter/material.dart';
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

class _HealthScreenState extends State<HealthScreen> {
  final _healthRepo = HealthRepository();
  final _petRepo = PetRepository();

  List<HealthReminder> _reminders = [];
  List<Pet> _pets = [];
  bool _sosActive = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
                    value: selectedPet,
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
                  child: Text(
                    tr(context, 'health_title'),
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
                Tooltip(
                  message: tr(context, 'export_card'),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.white12 : const Color(0xFFE8EEF8),
                      foregroundColor: HissouColors.primaryNavyLight,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Health Pass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Generating Digital Pet Health Passport PDF...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // SOS Radar Hero Card
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                                fontSize: 16,
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
                        activeColor: HissouColors.accentAmber,
                        activeTrackColor: Colors.white24,
                        onChanged: (val) async {
                          await _healthRepo.setSosActive(val);
                          if (!context.mounted) return;
                          setState(() => _sosActive = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val
                                  ? '🚨 SOS Broadcast active: nearby community alerted!'
                                  : 'SOS Broadcast deactivated.'),
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

            const SizedBox(height: 24),

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
                      daysUntil >= 0 ? 'Due in $daysUntil days' : 'Overdue',
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
