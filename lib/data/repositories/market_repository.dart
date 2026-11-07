import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/market_listing.dart';

class MarketRepository {
  static const _key = 'hissou_market_v1';

  final List<MarketListing> _defaultListings = [
    MarketListing(
      id: 'mkt_1',
      title: 'Loving 3-month-old Kitten looking for a warm home',
      description: 'Rescued kitten, fully vaccinated and litter-trained. Friendly with other cats and children. Free adoption to a verified loving family.',
      category: MarketCategory.adoption,
      price: 0.0,
      currency: '\$',
      location: 'Downtown Animal Shelter',
      contactPhone: '+1 555-0199',
      isVerified: true,
      species: 'cat',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MarketListing(
      id: 'mkt_2',
      title: 'Gentle Labrador Mix (2 yrs) seeking forever companion',
      description: 'Neutered, microchipped, obedient, and leash trained. Loves long walks and cuddling.',
      category: MarketCategory.adoption,
      price: 0.0,
      currency: '\$',
      location: 'Paws & Hope Rescue',
      contactPhone: '+1 555-0144',
      isVerified: true,
      species: 'dog',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MarketListing(
      id: 'mkt_3',
      title: 'Premium Ergonomic Pet Travel Carrier (Large)',
      description: 'Airline approved, ventilated mesh, like new. Used only once for a flight.',
      category: MarketCategory.supplies,
      price: 35.0,
      currency: '\$',
      location: 'West End',
      contactPhone: '+1 555-0177',
      isVerified: false,
      species: 'all',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    MarketListing(
      id: 'mkt_4',
      title: 'Certified Mobile Pet Grooming & Spa Service',
      description: 'Full hydrobath, deshedding, nail clipping, and ear cleaning right at your doorstep.',
      category: MarketCategory.services,
      price: 45.0,
      currency: '\$',
      location: 'Metropolitan Area',
      contactPhone: '+1 555-0188',
      isVerified: true,
      species: 'all',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  Future<List<MarketListing>> getListings({MarketCategory? category}) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key);
    List<MarketListing> all;
    if (rawList == null || rawList.isEmpty) {
      await saveListings(_defaultListings);
      all = _defaultListings;
    } else {
      all = rawList
          .map((item) => MarketListing.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    }

    if (category == null) return all;
    return all.where((item) => item.category == category).toList();
  }

  Future<void> saveListings(List<MarketListing> listings) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = listings.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList(_key, rawList);
  }

  Future<void> addListing(MarketListing listing) async {
    final list = await getListings();
    list.insert(0, listing);
    await saveListings(list);
  }

  Future<void> deleteListing(String id) async {
    final list = await getListings();
    list.removeWhere((l) => l.id == id);
    await saveListings(list);
  }
}
