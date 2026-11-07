import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services.dart';
import '../models/story.dart';

class StoryRepository {
  static const _key = 'hissou_stories_v1';

  final List<StoryPost> _defaultStories = [
    StoryPost(
      id: 'story_1',
      petId: 'pet_1',
      petName: 'Milo',
      species: 'dog',
      caption: 'Took Milo to the lake today! He swam for an hour and then made this happy bark when we unpacked the snacks.',
      likes: 24,
      isLiked: true,
      interpretation: Interpretation(
        mood: 'Joyful & Hungry',
        message: 'That water was amazing! Now hand over the biscuits!',
        advice: 'Offer fresh water after swimming to keep him well-hydrated.',
        confidence: 0.94,
        species: 'dog',
        petName: 'Milo',
        language: 'en',
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    StoryPost(
      id: 'story_2',
      petId: 'pet_2',
      petName: 'Luna',
      species: 'cat',
      caption: 'Luna found her ultimate cardboard box today. Refuses to leave it for dinner.',
      likes: 18,
      isLiked: false,
      interpretation: Interpretation(
        mood: 'Relaxed & Territorial',
        message: 'This is my royal fortress. Do not disturb my nap.',
        advice: 'Cardboard boxes provide cats with security and lower stress levels.',
        confidence: 0.88,
        species: 'cat',
        petName: 'Luna',
        language: 'en',
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
    ),
    StoryPost(
      id: 'story_3',
      petId: 'pet_ext_1',
      petName: 'Bella',
      species: 'bird',
      caption: 'Bella learned how to mimic the doorbell whistle this morning! 🐦',
      likes: 31,
      isLiked: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  Future<List<StoryPost>> getStories() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key);
    if (rawList == null || rawList.isEmpty) {
      await saveStories(_defaultStories);
      return _defaultStories;
    }
    return rawList
        .map((item) => StoryPost.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveStories(List<StoryPost> stories) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = stories.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_key, rawList);
  }

  Future<void> addStory(StoryPost story) async {
    final list = await getStories();
    list.insert(0, story);
    await saveStories(list);
  }

  Future<void> toggleLike(String storyId) async {
    final list = await getStories();
    final index = list.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final s = list[index];
      s.isLiked = !s.isLiked;
      s.likes += s.isLiked ? 1 : -1;
      await saveStories(list);
    }
  }
}
