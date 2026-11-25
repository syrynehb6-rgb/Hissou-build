import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_screen.dart';

class PrivacyConsentScreen extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;

  const PrivacyConsentScreen({super.key, required this.onLocaleChanged});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _acceptedTerms = false;
  bool _acceptedAudio = false;

  Future<void> _proceed() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez accepter les conditions d\'utilisation pour continuer.'),
          backgroundColor: HissouColors.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hissou_privacy_accepted', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => AuthScreen(onLocaleChanged: widget.onLocaleChanged),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HissouColors.primaryNavyDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HissouColors.accentAmber.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: HissouColors.accentAmber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Confidentialité & Sécurité',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Vos données félines et vocales sont protégées',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Scrollable Policy Points
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPolicyCard(
                        icon: Icons.mic_external_on_rounded,
                        title: 'Enregistrements Vocaux & Miaulements',
                        description:
                            'Les sons enregistrés par le microphone sont analysés par notre intelligence artificielle uniquement pour traduire l\'humeur de votre animal. Les enregistrements restent strictement sous votre contrôle.',
                        badge: 'Audio Sécurisé',
                        badgeColor: HissouColors.accentAmber,
                      ),
                      const SizedBox(height: 14),
                      _buildPolicyCard(
                        icon: Icons.lock_outline_rounded,
                        title: 'Protection de la Vie Privée (RGPD & Apple)',
                        description:
                            'Aucune information personnelle ou vocale n\'est vendue à des tiers. Vos données de commande et votre carnet de santé restent chiffrés et confidentiels.',
                        badge: '100% Privé',
                        badgeColor: HissouColors.successGreen,
                      ),
                      const SizedBox(height: 14),
                      _buildPolicyCard(
                        icon: Icons.pets_rounded,
                        title: 'Conditions Générales & Éthique Animale',
                        description:
                            'Hissou s\'engage pour le bien-être animal. Les conseils vétérinaires et alertes de santé sont fournis à titre d\'assistance et ne remplacent pas une urgence médicale clinique.',
                        badge: 'Bien-être Félin',
                        badgeColor: HissouColors.softRose,
                      ),
                      const SizedBox(height: 20),

                      // Checkboxes
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: _acceptedTerms,
                              onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                              activeColor: HissouColors.accentAmber,
                              checkColor: HissouColors.primaryNavyDark,
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'J\'ai lu et j\'accepte les Conditions d\'Utilisation et la Politique de Confidentialité.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white12, height: 16),
                            CheckboxListTile(
                              value: _acceptedAudio,
                              onChanged: (val) => setState(() => _acceptedAudio = val ?? false),
                              activeColor: HissouColors.accentAmber,
                              checkColor: HissouColors.primaryNavyDark,
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'J\'autorise l\'application à sauvegarder mes traductions et vocaux dans mon historique.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HissouColors.accentAmber,
                    foregroundColor: HissouColors.primaryNavyDark,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Accepter & Continuer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required IconData icon,
    required String title,
    required String description,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HissouColors.cardSurfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
