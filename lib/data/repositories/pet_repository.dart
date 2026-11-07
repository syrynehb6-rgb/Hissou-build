import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';

class PetRepository {
  static const _key = 'hissou_pets_v1';

  final List<Pet> _defaultPets = [
    const Pet(
      id: 'pet_1',
      name: 'Milo',
      species: 'dog',
      breed: 'Golden Retriever',
      age: '2 yrs',
      bio: 'Loves tennis balls, peanut butter, and long sunset runs.',
    ),
    const Pet(
      id: 'pet_2',
      name: 'Luna',
      species: 'cat',
      breed: 'British Shorthair',
      age: '1 yr',
      bio: 'Sunbath connoisseur and champion bird watcher.',
    ),
  ];

  Future<List<Pet>> getPets() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key);
    if (rawList == null || rawList.isEmpty) {
      await savePets(_defaultPets);
      return _defaultPets;
    }
    return rawList
        .map((item) => Pet.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePets(List<Pet> pets) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = pets.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_key, rawList);
  }

  Future<void> addPet(Pet pet) async {
    final list = await getPets();
    list.add(pet);
    await savePets(list);
  }

  Future<void> deletePet(String id) async {
    final list = await getPets();
    list.removeWhere((p) => p.id == id);
    await savePets(list);
  }
}
