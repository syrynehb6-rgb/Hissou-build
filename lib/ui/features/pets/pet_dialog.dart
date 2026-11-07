import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pet.dart';
import '../../../l10n.dart';

class PetDialog extends StatefulWidget {
  final ValueChanged<Pet> onSaved;

  const PetDialog({super.key, required this.onSaved});

  @override
  State<PetDialog> createState() => _PetDialogState();
}

class _PetDialogState extends State<PetDialog> {
  final _nameCtl = TextEditingController();
  final _breedCtl = TextEditingController();
  final _ageCtl = TextEditingController();
  final _bioCtl = TextEditingController();
  String _species = 'dog';

  @override
  void dispose() {
    _nameCtl.dispose();
    _breedCtl.dispose();
    _ageCtl.dispose();
    _bioCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'add_pet'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: HissouColors.primaryNavy,
                    ),
              ),
              const SizedBox(height: 16),
              // Species Chips
              Wrap(
                spacing: 8,
                children: [
                  for (final s in ['dog', 'cat', 'bird', 'horse'])
                    ChoiceChip(
                      label: Text(tr(context, s)),
                      selected: _species == s,
                      onSelected: (_) => setState(() => _species = s),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameCtl,
                decoration: InputDecoration(
                  labelText: tr(context, 'name'),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _breedCtl,
                decoration: InputDecoration(
                  labelText: tr(context, 'pet_breed'),
                  prefixIcon: const Icon(Icons.pets_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ageCtl,
                decoration: InputDecoration(
                  labelText: tr(context, 'pet_age'),
                  prefixIcon: const Icon(Icons.cake_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioCtl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: tr(context, 'pet_bio'),
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr(context, 'cancel')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameCtl.text.trim();
                      if (name.isEmpty) return;
                      final pet = Pet(
                        id: 'pet_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        species: _species,
                        breed: _breedCtl.text.trim(),
                        age: _ageCtl.text.trim(),
                        bio: _bioCtl.text.trim(),
                      );
                      widget.onSaved(pet);
                      Navigator.pop(context);
                    },
                    child: Text(tr(context, 'save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
