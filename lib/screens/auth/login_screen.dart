import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _obscurePassword = true;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late AnimationController _logoController;
  late AnimationController _btnController;

  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _logoScale;
  late Animation<double> _btnScale;
  late Animation<Alignment> _gradientAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _gradientAnim = AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomRight)
        .animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _cardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _cardSlide = Tween<double>(begin: 80, end: 0)
        .animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeIn);

    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _btnScale = _btnController;

    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passwordFocus.addListener(() => setState(() => _passwordFocused = _passwordFocus.hasFocus));

    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _logoController.forward(); });
    Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _cardController.forward(); });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _logoController.dispose();
    _btnController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    _btnController.reverse();
    setState(() => _isLoading = true);

    final notifier = UserProvider.of(context);
    final error = await notifier.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    _btnController.forward();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
      return;
    }

    // Load full profile (height, weight, targets, etc.) before navigating
    await notifier.loadProfile();
    if (!mounted) return;

    final onboarded = notifier.user?.onboardingDone ?? false;
    Navigator.pushNamedAndRemoveUntil(
      context,
      onboarded ? '/dashboard' : '/onboarding',
      (_) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: _gradientAnim,
        builder: (_, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [Color(0xFF0D1B2A), Color(0xFF1B4332), Color(0xFF00C853)],
              begin: _gradientAnim.value,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                  children: [
                    // ── Logo ──────────────────────────────────────────────
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: _logoScale,
                              child: Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00C853).withValues(alpha: 0.5),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Center(child: Text('🥗', style: TextStyle(fontSize: 44))),
                              ),
                            ),
                            const SizedBox(height: 18),
                            ScaleTransition(
                              scale: _logoScale,
                              child: const Column(children: [
                                Text('MealSense',
                                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                SizedBox(height: 6),
                                Text('Your smart nutrition companion',
                                    style: TextStyle(color: Colors.white60, fontSize: 13, letterSpacing: 0.3)),
                              ]),
                            ),
                            const SizedBox(height: 20),
                            ScaleTransition(
                              scale: _logoScale,
                              child: Wrap(
                                spacing: 10,
                                children: const [
                                  _FeaturePill(icon: '🔥', label: 'Track Calories'),
                                  _FeaturePill(icon: '💧', label: 'Hydration'),
                                  _FeaturePill(icon: '🏋️', label: 'Fitness'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Card ──────────────────────────────────────────────
                    AnimatedBuilder(
                      animation: _cardController,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _cardSlide.value),
                        child: FadeTransition(opacity: _cardFade, child: child),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFB),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(36),
                            topRight: Radius.circular(36),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            28, 28, 28,
                            MediaQuery.of(context).viewInsets.bottom + 28,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Container(
                                    width: 40, height: 4,
                                    margin: const EdgeInsets.only(bottom: 22),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const Text('Welcome back 👋',
                                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                                const SizedBox(height: 4),
                                Text('Sign in to continue your health journey',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                const SizedBox(height: 24),

                                // Email field
                                _GlowField(
                                  controller: _emailCtrl,
                                  focusNode: _emailFocus,
                                  focused: _emailFocused,
                                  hint: 'Email address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Email is required';
                                    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim())) return 'Enter a valid email';
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 14),

                                // Password field
                                _GlowField(
                                  controller: _passwordCtrl,
                                  focusNode: _passwordFocus,
                                  focused: _passwordFocused,
                                  hint: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey.shade400, size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    if (v.length < 6) return 'Min 6 characters';
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('Sign in with your email & password',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                ),
                                const SizedBox(height: 22),

                                // Send OTP button
                                ScaleTransition(
                                  scale: _btnScale,
                                  child: GestureDetector(
                                    onTapDown: (_) => _btnController.reverse(),
                                    onTapUp: (_) => _btnController.forward(),
                                    onTapCancel: () => _btnController.forward(),
                                    onTap: _isLoading ? null : _login,
                                    child: Container(
                                      width: double.infinity,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF00C853), Color(0xFF00897B)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00C853).withValues(alpha: 0.4),
                                            blurRadius: 18,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(width: 24, height: 24,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                            : const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Login',
                                                      style: TextStyle(color: Colors.white, fontSize: 16,
                                                          fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                                  SizedBox(width: 8),
                                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                Row(children: [
                                  Expanded(child: Divider(color: Colors.grey.shade200)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('or', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey.shade200)),
                                ]),
                                const SizedBox(height: 14),

                                Center(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/signup'),
                                    child: RichText(
                                      text: TextSpan(
                                        text: "Don't have an account? ",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                        children: const [
                                          TextSpan(
                                            text: 'Sign Up',
                                            style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Glow Input Field ──────────────────────────────────────────────────────────

class _GlowField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _GlowField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: focused
            ? [BoxShadow(color: const Color(0xFF00C853).withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15, color: Color(0xFF0D1B2A), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: focused ? const Color(0xFF00C853) : Colors.grey.shade400, size: 22),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF00C853), width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE53935), width: 2)),
        ),
      ),
    );
  }
}

// ─── Feature Pill ──────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final String icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
