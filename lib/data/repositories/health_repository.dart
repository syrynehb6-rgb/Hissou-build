import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_record.dart';

class HealthRepository {
  static const _remindersKey = 'hissou_health_reminders_v1';
  static const _sosKey = 'hissou_sos_active_v1';

  final List<HealthReminder> _defaultReminders = [
    HealthReminder(
      id: 'rem_1',
      petId: 'pet_1',
      petName: 'Milo',
      title: 'Annual Rabies & DHPP Booster',
      type: ReminderType.vaccine,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      notes: 'Scheduled at Central Animal Clinic with Dr. Miller.',
    ),
    HealthReminder(
      id: 'rem_2',
      petId: 'pet_2',
      petName: 'Luna',
      title: 'Quarterly Deworming Tablet',
      type: ReminderType.deworming,
      dueDate: DateTime.now().add(const Duration(days: 12)),
      notes: 'Administer with wet food after dinner.',
    ),
    HealthReminder(
      id: 'rem_3',
      petId: 'pet_1',
      petName: 'Milo',
      title: 'Full Coat Deshedding & Nail Trim',
      type: ReminderType.grooming,
      dueDate: DateTime.now().add(const Duration(days: 18)),
      notes: 'At Paws Grooming Studio.',
    ),
  ];

  Future<List<HealthReminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_remindersKey);
    if (rawList == null || rawList.isEmpty) {
      await saveReminders(_defaultReminders);
      return _defaultReminders;
    }
    return rawList
        .map((item) => HealthReminder.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveReminders(List<HealthReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = reminders.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_remindersKey, rawList);
  }

  Future<void> addReminder(HealthReminder reminder) async {
    final list = await getReminders();
    list.add(reminder);
    await saveReminders(list);
  }

  Future<void> toggleCompleted(String id) async {
    final list = await getReminders();
    final index = list.indexWhere((r) => r.id == id);
    if (index != -1) {
      list[index].isCompleted = !list[index].isCompleted;
      await saveReminders(list);
    }
  }

  Future<bool> isSosActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sosKey) ?? false;
  }

  Future<void> setSosActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sosKey, active);
  }
}
