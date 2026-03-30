import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/otp_input_widget.dart';

class OtpScreen extends StatefulWidget {
  final String contact;
  final String destination; // '/onboarding' or '/dashboard'
  const OtpScreen({super.key, required this.contact, this.destination = '/onboarding'});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  // ── Simulated correct OTP ──────────────────────────────────────────────────
  static const _correctOtp = '123456';

  String _otp = '';
  bool _hasError = false;
  bool _isVerifying = false;
  bool _isSuccess = false;
  String _errorMessage = '';

  // ── Timer ──────────────────────────────────────────────────────────────────
  int _secondsLeft = 30;
  Timer? _timer;
  bool _canResend = false;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _entranceController;
  late AnimationController _successController;
  late AnimationController _btnController;

  late Animation<Offset> _headerSlide;
  late Animation<Offset> _cardSlide;
  late Animation<double> _fade;
  late Animation<double> _successScale;
  late Animation<double> _successOpacity;
  late Animation<double> _btnScale;

  final GlobalKey<OtpInputWidgetState> _otpKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _fade = CurvedAnimation(parent: _entranceController, curve: Curves.easeIn);
    _entranceController.forward();

    // Success
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successOpacity = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeIn,
    );

    // Button
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _btnScale = _btnController;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entranceController.dispose();
    _successController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _resendOtp() {
    if (!_canResend) return;
    setState(() {
      _otp = '';
      _hasError = false;
      _errorMessage = '';
    });
    _otpKey.currentState?.clear();
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('OTP resent successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter the complete 6-digit OTP';
      });
      return;
    }

    _btnController.reverse();
    setState(() {
      _isVerifying = true;
      _hasError = false;
      _errorMessage = '';
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));
    _btnController.forward();

    if (!mounted) return;

    if (_otp == _correctOtp) {
      _timer?.cancel();
      setState(() {
        _isVerifying = false;
        _isSuccess = true;
      });
      _successController.forward();
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, widget.destination, (_) => false);
    } else {
      setState(() {
        _isVerifying = false;
        _hasError = true;
        _errorMessage = 'Incorrect OTP. Please try again.';
      });
    }
  }

  String get _maskedContact {
    final c = widget.contact.trim();
    if (c.contains('@')) {
      final parts = c.split('@');
      final name = parts[0];
      final masked = name.length > 3
          ? '${name.substring(0, 3)}***@${parts[1]}'
          : '***@${parts[1]}';
      return masked;
    } else if (c.length >= 10) {
      return '${c.substring(0, 2)}******${c.substring(c.length - 2)}';
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          // ── Background gradient top ──────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1B2A), Color(0xFF1B4332), Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  // ── Header ───────────────────────────────────────────────
                  SlideTransition(
                    position: _headerSlide,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline_rounded,
                                    color: Colors.white70, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'Secure Verification',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Hero area ─────────────────────────────────────────────
                  SlideTransition(
                    position: _headerSlide,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verify your\nidentity 🔐',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              text: 'OTP sent to  ',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: _maskedContact,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Card ──────────────────────────────────────────────────
                  Expanded(
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(36),
                            topRight: Radius.circular(36),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                          child: _isSuccess
                              ? _SuccessView(
                                  scale: _successScale,
                                  opacity: _successOpacity,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Handle
                                    Center(
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        margin: const EdgeInsets.only(bottom: 28),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),

                                    const Text(
                                      'Enter OTP',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D1B2A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Use 123456 to simulate a correct OTP',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade400),
                                    ),
                                    const SizedBox(height: 32),

                                    // OTP Input
                                    OtpInputWidget(
                                      key: _otpKey,
                                      length: 6,
                                      hasError: _hasError,
                                      onChanged: (v) => setState(() {
                                        _otp = v;
                                        if (_hasError) {
                                          _hasError = false;
                                          _errorMessage = '';
                                        }
                                      }),
                                      onCompleted: (v) {
                                        setState(() => _otp = v);
                                        _verifyOtp();
                                      },
                                    ),

                                    // Error message
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 250),
                                      child: _hasError
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: 14),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.error_outline_rounded,
                                                    color: Color(0xFFE53935),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _errorMessage,
                                                    style: const TextStyle(
                                                      color: Color(0xFFE53935),
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    const SizedBox(height: 32),

                                    // Timer / Resend
                                    Center(
                                      child: _canResend
                                          ? GestureDetector(
                                              onTap: _resendOtp,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 20, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE8F5E9),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.refresh_rounded,
                                                        color: Color(0xFF00C853),
                                                        size: 16),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Resend OTP',
                                                      style: TextStyle(
                                                        color: Color(0xFF00C853),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : _TimerWidget(seconds: _secondsLeft),
                                    ),
                                    const SizedBox(height: 36),

                                    // Verify button
                                    ScaleTransition(
                                      scale: _btnScale,
                                      child: GestureDetector(
                                        onTapDown: (_) => _btnController.reverse(),
                                        onTapUp: (_) => _btnController.forward(),
                                        onTapCancel: () => _btnController.forward(),
                                        onTap: _isVerifying ? null : _verifyOtp,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          width: double.infinity,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: _otp.length == 6
                                                  ? const [
                                                      Color(0xFF00C853),
                                                      Color(0xFF00897B)
                                                    ]
                                                  : [
                                                      Colors.grey.shade300,
                                                      Colors.grey.shade300,
                                                    ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(18),
                                            boxShadow: _otp.length == 6
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF00C853)
                                                          .withValues(alpha: 0.4),
                                                      blurRadius: 18,
                                                      offset: const Offset(0, 7),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: _isVerifying
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Verify OTP',
                                                        style: TextStyle(
                                                          color: _otp.length == 6
                                                              ? Colors.white
                                                              : Colors.grey.shade500,
                                                          fontSize: 17,
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Icon(
                                                        Icons.verified_rounded,
                                                        color: _otp.length == 6
                                                            ? Colors.white
                                                            : Colors.grey.shade400,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Wrong OTP hint
                                    Center(
                                      child: Text(
                                        'Wrong OTP will show an error message',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 12,
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
        ],
      ),
    );
  }
}

// ─── Timer Widget ──────────────────────────────────────────────────────────────

class _TimerWidget extends StatelessWidget {
  final int seconds;
  const _TimerWidget({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final progress = seconds / 30;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  seconds > 10 ? const Color(0xFF00C853) : const Color(0xFFE53935),
                ),
              ),
              Center(
                child: Text(
                  '$seconds',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: seconds > 10
                        ? const Color(0xFF00C853)
                        : const Color(0xFFE53935),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Resend OTP in ${seconds}s',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Success View ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final Animation<double> scale;
  final Animation<double> opacity;
  const _SuccessView({required this.scale, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(
        scale: scale,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00897B)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Verified! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Taking you to your health journey...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
