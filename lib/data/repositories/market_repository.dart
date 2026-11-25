import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/market_listing.dart';

class MarketRepository {
  static const _key = 'hissou_market_v2'; // upgraded key for rich listings

  final List<MarketListing> _defaultListings = [
    // ADOPTIONS
    MarketListing(
      id: 'mkt_adopt_1',
      title: 'Chaton Angora Blanc (3 mois) très affectueux & vacciné',
      description: 'Chaton sevré, propre et joueur. Vermifugé avec carnet de santé à jour. Cherche famille aimante pour adoption responsable.',
      category: MarketCategory.adoption,
      price: 0.0,
      currency: 'TND',
      location: 'La Marsa, Tunis',
      contactPhone: '+216 98 111 222',
      isVerified: true,
      species: 'cat',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    MarketListing(
      id: 'mkt_adopt_2',
      title: 'Chatte Européenne Calico stérilisée (1 an)',
      description: 'Douce et calme en appartement. Habituée aux enfants et aux autres animaux. Adoption gratuite avec suivi vétérinaire offert.',
      category: MarketCategory.adoption,
      price: 0.0,
      currency: 'TND',
      location: 'Menzah 9, Tunis',
      contactPhone: '+216 98 333 444',
      isVerified: true,
      species: 'cat',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),

    // SUPPLIES (PRODUCTS READY FOR ORDERS)
    MarketListing(
      id: 'mkt_sup_1',
      title: 'Croquettes Royal Canin Félin Stérilisé (Sac 4kg)',
      description: 'Nutrition complète haut de gamme pour chats d\'intérieur stérilisés. Contrôle du poids et santé des voies urinaires. Emballage scellé garanti.',
      category: MarketCategory.supplies,
      price: 68.0,
      currency: 'TND',
      location: 'Boutique Hissou Express',
      contactPhone: '+216 71 888 999',
      isVerified: true,
      species: 'cat',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MarketListing(
      id: 'mkt_sup_2',
      title: 'Litière Végétale Ultra Absorbante & Agglomérante (10L)',
      description: '100% naturelle et biodégradable. Élimine les odeurs instantanément sans poussière. Douce pour les coussinets sensibles.',
      category: MarketCategory.supplies,
      price: 24.5,
      currency: 'TND',
      location: 'Stock Central Tunis',
      contactPhone: '+216 71 888 999',
      isVerified: true,
      species: 'cat',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    MarketListing(
      id: 'mkt_sup_3',
      title: 'Sac de Transport Aérien Panoramique Deluxe Hissou',
      description: 'Respirant, homologué IATA cabine, ouverture frontale et supérieure avec coussin polaire lavable amovible. Coloris Bleu Nuit.',
      category: MarketCategory.supplies,
      price: 85.0,
      currency: 'TND',
      location: 'Boutique Hissou Express',
      contactPhone: '+216 71 888 999',
      isVerified: true,
      species: 'cat',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    MarketListing(
      id: 'mkt_sup_4',
      title: 'Fontaine à Eau Automatique Silencieuse en Inox (2.5L)',
      description: 'Filtration quadruple charbon actif avec débit réglable en cascade. Incite le chat à s\'hydrater pour prévenir les calculs rénaux.',
      category: MarketCategory.supplies,
      price: 55.0,
      currency: 'TND',
      location: 'Stock Central Tunis',
      contactPhone: '+216 71 888 999',
      isVerified: true,
      species: 'cat',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),

    // SERVICES (ORDERS & BOOKINGS)
    MarketListing(
      id: 'mkt_srv_1',
      title: 'Consultation Vétérinaire Complète à Domicile',
      description: 'Examen clinique général, pesée, bilan nutritionnel et conseils vaccinaux par un médecin vétérinaire certifié sans stress de transport.',
      category: MarketCategory.services,
      price: 50.0,
      currency: 'TND',
      location: 'Grand Tunis (À Domicile)',
      contactPhone: '+216 99 555 666',
      isVerified: true,
      species: 'all',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MarketListing(
      id: 'mkt_srv_2',
      title: 'Toilettage Félin Relaxant & Spa sans Anesthésie',
      description: 'Démêlage tout en douceur, bain aux huiles naturelles apaisantes, séchage tiède silencieux et coupe de griffes soignée.',
      category: MarketCategory.services,
      price: 45.0,
      currency: 'TND',
      location: 'Salon Partenaire Hissou Lac 2',
      contactPhone: '+216 99 777 888',
      isVerified: true,
      species: 'cat',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
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
