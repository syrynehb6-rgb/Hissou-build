import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../navigation/adaptive_scaffold.dart';

class AuthScreen extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;

  const AuthScreen({super.key, required this.onLocaleChanged});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth({bool isGuest = false, String provider = 'email'}) async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hissou_user_logged_in', true);

    if (isGuest) {
      await prefs.setString('hissou_user_name', 'Invité Félin');
      await prefs.setString('hissou_user_email', 'guest@hissou.app');
    } else if (provider == 'apple') {
      await prefs.setString('hissou_user_name', 'Apple User');
      await prefs.setString('hissou_user_email', 'user@privaterelay.appleid.com');
    } else if (provider == 'google') {
      await prefs.setString('hissou_user_name', 'Google User');
      await prefs.setString('hissou_user_email', 'user@gmail.com');
    } else {
      final name = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Ami des Chats';
      await prefs.setString('hissou_user_name', name);
      await prefs.setString('hissou_user_email', _emailController.text.trim());
    }

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => AdaptiveScaffold(onLocaleChanged: widget.onLocaleChanged),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Header
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [HissouColors.accentAmber, HissouColors.softRose],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: HissouColors.accentAmber.withAlpha(60),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      width: 68,
                      height: 68,
                      color: HissouColors.primaryNavy,
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Bienvenue sur Hissou',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Connectez-vous pour synchroniser vos chats & commandes',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 24),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: HissouColors.cardSurfaceDark,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Tabs
                      Container(
                        height: 44,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: HissouColors.accentAmber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: HissouColors.primaryNavyDark,
                          unselectedLabelColor: Colors.white70,
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          tabs: const [
                            Tab(text: 'Se Connecter'),
                            Tab(text: 'Créer un Compte'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form Fields
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          final isSignUp = _tabController.index == 1;
                          return Column(
                            children: [
                              if (isSignUp) ...[
                                _buildInputField(
                                  controller: _nameController,
                                  label: 'Nom Complet / Pseudo',
                                  icon: Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: 12),
                              ],
                              _buildInputField(
                                controller: _emailController,
                                label: 'Adresse Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                controller: _passwordController,
                                label: 'Mot de passe',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                              ),
                              const SizedBox(height: 20),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : () => _handleAuth(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: HissouColors.accentAmber,
                                    foregroundColor: HissouColors.primaryNavyDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: HissouColors.primaryNavyDark,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          isSignUp ? 'Créer mon Compte' : 'Se Connecter',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 18),
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Colors.white12)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'OU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white12)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Social Logins
                      // Apple ID (Required for iOS App Store compliance)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : () => _handleAuth(provider: 'apple'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.apple, size: 22, color: Colors.black),
                          label: const Text(
                            'Continuer avec Apple',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Google Login
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : () => _handleAuth(provider: 'google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.g_mobiledata_rounded, size: 26, color: Colors.white),
                          label: const Text(
                            'Continuer avec Google',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Guest / Visitor Button
                TextButton.icon(
                  onPressed: _loading ? null : () => _handleAuth(isGuest: true),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: HissouColors.accentAmber),
                  label: const Text(
                    'Continuer en tant qu\'Invité (Sans compte)',
                    style: TextStyle(
                      color: HissouColors.accentAmber,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
        prefixIcon: Icon(icon, size: 18, color: HissouColors.accentAmber),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: Colors.white60,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        isDense: true,
        filled: true,
        fillColor: Colors.white.withAlpha(8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: HissouColors.accentAmber, width: 1.5),
        ),
      ),
    );
  }
}
