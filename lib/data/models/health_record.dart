enum ReminderType { vaccine, vet, deworming, grooming }

class HealthReminder {
  final String id;
  final String petId;
  final String petName;
  final String title;
  final ReminderType type;
  final DateTime dueDate;
  bool isCompleted;
  final String notes;

  HealthReminder({
    required this.id,
    required this.petId,
    required this.petName,
    required this.title,
    required this.type,
    required this.dueDate,
    this.isCompleted = false,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'petId': petId,
        'petName': petName,
        'title': title,
        'type': type.name,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted,
        'notes': notes,
      };

  factory HealthReminder.fromJson(Map<String, dynamic> json) => HealthReminder(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        petId: json['petId'] as String? ?? '',
        petName: json['petName'] as String? ?? 'Pet',
        title: json['title'] as String? ?? '',
        type: ReminderType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => ReminderType.vaccine,
        ),
        dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
        isCompleted: json['isCompleted'] as bool? ?? false,
        notes: json['notes'] as String? ?? '',
      );
}
