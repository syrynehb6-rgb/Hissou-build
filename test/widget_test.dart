import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissou/data/models/market_listing.dart';
import 'package:hissou/data/models/pet.dart';
import 'package:hissou/data/models/story.dart';
import 'package:hissou/main.dart';
import 'package:hissou/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI & Navigation Tests', () {
    testWidgets('T1: renders Adaptive Navigation with Stories, Voice, Market, and Care tabs', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const HissouApp());
      await tester.pumpAndSettle();

      // Header & brand
      expect(find.text('Hissou'), findsOneWidget);
      expect(find.text('Pet Chronicles'), findsOneWidget);

      // Bottom Navigation items
      expect(find.text('Stories'), findsOneWidget);
      expect(find.text('AI Voice'), findsOneWidget);
      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Care & SOS'), findsOneWidget);

      // Switch to AI Voice tab
      await tester.tap(find.text('AI Voice'));
      await tester.pumpAndSettle();
      expect(find.text('Tap to record'), findsOneWidget);
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);

      // Switch to Market tab
      await tester.tap(find.text('Market'));
      await tester.pumpAndSettle();
      expect(find.text('Hissou Market'), findsOneWidget);
      expect(find.text('Adoption'), findsOneWidget);
      expect(find.text('Supplies'), findsOneWidget);

      // Switch to Care & SOS tab
      await tester.tap(find.text('Care & SOS'));
      await tester.pumpAndSettle();
      expect(find.text('Health & Care Vault'), findsOneWidget);
      expect(find.text('Lost & Found SOS Radar'), findsOneWidget);
    });

    testWidgets('T2: switches locale between English, French, and Arabic (RTL)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const HissouApp());
      await tester.pumpAndSettle();

      // Switch to French
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();
      expect(find.text('Histoires'), findsOneWidget);
      expect(find.text('Marché'), findsOneWidget);

      // Switch to Arabic (and verify RTL directionality)
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(find.text('حسّو'), findsOneWidget);
      expect(find.text('القصص'), findsOneWidget);
      expect(find.text('السوق والتبني'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text('القصص'))), TextDirection.rtl);
    });
  });

  group('Model Serialization Tests', () {
    test('T3: Interpretation JSON round-trip preserves all fields', () {
      final orig = Interpretation(
        mood: 'Playful',
        message: 'Throw the ball for me!',
        advice: 'Play fetch for 10 minutes.',
        confidence: 0.91,
        species: 'dog',
        petName: 'Rex',
        language: 'en',
      );
      final copy = Interpretation.fromJson(orig.toJson());
      expect(copy.mood, 'Playful');
      expect(copy.message, 'Throw the ball for me!');
      expect(copy.advice, 'Play fetch for 10 minutes.');
      expect(copy.confidence, closeTo(0.91, 0.001));
      expect(copy.species, 'dog');
      expect(copy.petName, 'Rex');
      expect(copy.language, 'en');
    });

    test('T4: Pet, StoryPost, and MarketListing round-trip', () {
      final pet = Pet(id: '1', name: 'Milo', species: 'dog', breed: 'Retriever');
      expect(Pet.fromJson(pet.toJson()).name, 'Milo');

      final story = StoryPost(
        id: 's1',
        petId: '1',
        petName: 'Milo',
        species: 'dog',
        caption: 'Beach day!',
        likes: 5,
      );
      expect(StoryPost.fromJson(story.toJson()).caption, 'Beach day!');

      final market = MarketListing(
        id: 'm1',
        title: 'Puppy Carrier',
        description: 'New carrier',
        category: MarketCategory.supplies,
        price: 25,
        location: 'City Center',
        contactPhone: '+123456789',
      );
      expect(MarketListing.fromJson(market.toJson()).price, 25);
    });
  });
}
