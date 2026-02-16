import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../screens/order_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late Animation<double> _logoPulseAnimation;

  @override
  void initState() {
    super.initState();
    // Prefill with a cashier test account from the seed data
    _emailController.text = 'cashier1@example.com';
    _passwordController.text = 'password123';

    // Initialize fade animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _logoPulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _checkExistingSession();
    _loadRememberedCredentials();
    
    // Start timer for real-time clock
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('remembered_email');
    final rememberedPassword = prefs.getString('remembered_password');
    final shouldRemember = prefs.getBool('remember_me') ?? false;

    if (shouldRemember && rememberedEmail != null) {
      setState(() {
        _rememberMe = true;
        _emailController.text = rememberedEmail;
        if (rememberedPassword != null) {
          _passwordController.text = rememberedPassword;
        }
      });
    }
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final cashierId = prefs.getString('cashier_id');

    if (token != null && cashierId != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OrderScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Save credentials if remember me is checked
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailController.text.trim());
        await prefs.setString('remembered_password', _passwordController.text);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('remembered_email');
        await prefs.remove('remembered_password');
        await prefs.setBool('remember_me', false);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrderScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _floatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 900;

    return Scaffold(
      body: isSmallScreen ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left section - Promotional green area
        Expanded(
          flex: 5,
          child: _buildPromotionalSection(),
        ),
        // Right section - Login form
        Expanded(
          flex: 5,
          child: _buildLoginSection(),
        ),
      ],
    );
  }

  Widget _buildLogoMark({
    double height = 56,
    Color? tintColor,
    bool withGlow = false,
  }) {
    final logo = Image.asset(
      'assets/images/logo_green.webp',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => Icon(
        Icons.point_of_sale,
        size: height * 0.8,
        color: tintColor ?? TawsilColors.primary,
      ),
    );

    final tintedLogo = tintColor == null
        ? logo
        : ColorFiltered(
            colorFilter: ColorFilter.mode(tintColor, BlendMode.srcIn),
            child: logo,
          );

    final logoBox = SizedBox(
      height: height,
      width: height * 3.2,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: tintedLogo,
      ),
    );

    if (!withGlow) return logoBox;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: logoBox,
    );
  }

  Widget _buildFloatingOrb({
    required double size,
    required Color color,
    required Alignment alignment,
    double offsetMultiplier = 1,
  }) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Align(
          alignment: alignment,
          child: Transform.translate(
            offset: Offset(0, _floatAnimation.value * offsetMultiplier),
            child: child,
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 32,
              spreadRadius: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionalSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TawsilColors.primaryDark,
            TawsilColors.primary,
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            _buildFloatingOrb(
              size: 220,
              color: TawsilColors.primaryLight.withOpacity(0.2),
              alignment: Alignment.topRight,
              offsetMultiplier: 0.6,
            ),
            _buildFloatingOrb(
              size: 260,
              color: TawsilColors.accent.withOpacity(0.12),
              alignment: Alignment.bottomLeft,
              offsetMultiplier: -0.4,
            ),
            _buildFloatingOrb(
              size: 140,
              color: Colors.white.withOpacity(0.08),
              alignment: Alignment.centerRight,
              offsetMultiplier: 0.8,
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(48),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    AnimatedBuilder(
                      animation: _logoPulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _logoPulseAnimation.value,
                        child: child,
                      ),
                      child: _buildLogoMark(
                        height: 58,
                        tintColor: Colors.white,
                        withGlow: true,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Title
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        children: [
                          const TextSpan(text: 'Système POS '),
                          TextSpan(
                            text: 'Intelligent',
                            style: TextStyle(color: TawsilColors.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Description
                    Text(
                      'Pilotez vos commandes, visualisez vos ventes et accélérez la prise en charge.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildFeatureChip(
                          icon: Icons.receipt_long,
                          label: 'Tickets instantanés',
                        ),
                        _buildFeatureChip(
                          icon: Icons.insights,
                          label: 'Statistiques claires',
                        ),
                        _buildFeatureChip(
                          icon: Icons.local_shipping_outlined,
                          label: 'Livraison fluide',
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Date and time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 18, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_currentTime),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.white.withOpacity(0.8)),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(_currentTime),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLoginSection() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            // Background logo with reduced opacity
            Positioned.fill(
              child: Opacity(
                opacity: 0.04,
                child: Center(
                  child: Image.asset(
                    'assets/images/logo_green.webp',
                    width: 400,
                    height: 400,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            // Login form
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildLoginForm(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            TawsilColors.primaryDark,
            TawsilColors.primary,
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            _buildFloatingOrb(
              size: 180,
              color: TawsilColors.primaryLight.withOpacity(0.2),
              alignment: Alignment.topRight,
              offsetMultiplier: 0.6,
            ),
            _buildFloatingOrb(
              size: 220,
              color: TawsilColors.accent.withOpacity(0.16),
              alignment: Alignment.topLeft,
              offsetMultiplier: -0.5,
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  // Top section with logo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _logoPulseAnimation,
                          builder: (context, child) => Transform.scale(
                            scale: _logoPulseAnimation.value,
                            child: child,
                          ),
                          child: _buildLogoMark(
                            height: 64,
                            tintColor: Colors.white,
                            withGlow: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bienvenue sur le POS Tawsil',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connectez-vous pour démarrer votre service.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildHighlightPill('Caisse rapide'),
                            _buildHighlightPill('Impression facile'),
                            _buildHighlightPill('Suivi livraison'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Login form card
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Stack(
                      children: [
                        // Background logo with reduced opacity
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.035,
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo_green.webp',
                                width: 260,
                                height: 260,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                        // Login form
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildLoginForm(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }


  InputDecoration _buildInputDecoration(
    String hintText, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: TawsilColors.textHint, fontSize: 16),
      filled: true,
      fillColor: TawsilColors.background,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TawsilColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TawsilColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TawsilColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TawsilColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TawsilColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }


  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Connexion',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: TawsilColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accédez à votre système de caisse',
            style: TextStyle(
              fontSize: 15,
              color: TawsilColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: TawsilColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                border: Border.all(color: TawsilColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: TawsilColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: TawsilColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Nom d\'utilisateur',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TawsilColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 16, color: TawsilColors.textPrimary),
            decoration: _buildInputDecoration(
              'Entrez votre identifiant',
              prefixIcon: Icon(Icons.person_outline, color: TawsilColors.textSecondary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre nom d\'utilisateur';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Mot de passe',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TawsilColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(fontSize: 16, color: TawsilColors.textPrimary),
            decoration: _buildInputDecoration(
              '••••••••',
              prefixIcon: Icon(Icons.lock_outline, color: TawsilColors.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: TawsilColors.textSecondary,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe';
              }
              if (value.length < 6) {
                return 'Le mot de passe doit contenir au moins 6 caracteres';
              }
              return null;
            },
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 360;
              final rememberRow = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                    activeColor: TawsilColors.primary,
                  ),
                  Flexible(
                    child: Text(
                      'Se souvenir de moi',
                      style: TextStyle(
                        fontSize: 14,
                        color: TawsilColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
              final forgotButton = TextButton(
                onPressed: () {
                  // TODO: Implement forgot password
                },
                child: Text(
                  'Mot de passe oublié?',
                  style: TextStyle(
                    fontSize: 14,
                    color: TawsilColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    rememberRow,
                    Align(
                      alignment: Alignment.centerRight,
                      child: forgotButton,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  rememberRow,
                  const Spacer(),
                  forgotButton,
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _login,
              icon: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_rounded, size: 20),
              label: _isLoading
                  ? const SizedBox.shrink()
                  : Text(
                      'Accéder au POS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TawsilColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: TawsilColors.primary.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


