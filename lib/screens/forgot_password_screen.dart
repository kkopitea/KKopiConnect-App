import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isLeaving = false;
  late final AnimationController _cardController;
  late final Animation<Offset> _cardSlideAnimation;
  Animation<Offset>? _imageSlideAnimation;
  Animation<double>? _cardFadeAnimation;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    final cardCurve = CurvedAnimation(parent: _cardController, curve: Curves.easeInOutCubic);
    _cardSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.23), end: Offset.zero).animate(cardCurve);
    _imageSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.24), end: Offset.zero).animate(cardCurve);
    _cardFadeAnimation = Tween<double>(begin: 0, end: 1).animate(cardCurve);
    _cardController.forward();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
      await _handleBack();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = error.code == 'user-not-found'
          ? 'No account was found for this email.'
          : 'Unable to send the verification email.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (_isLeaving) return;
    _isLeaving = true;
    await _cardController.reverse();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight = (constraints.maxHeight * 0.45).clamp(320.0, 390.0);
            return SizedBox(
              height: heroHeight + 520,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _HeroHeader(width: constraints.maxWidth, height: heroHeight, slideAnimation: _imageSlideAnimation ?? const AlwaysStoppedAnimation<Offset>(Offset.zero)),
                  Positioned(
                    top: heroHeight - 120,
                    left: 0,
                    right: 0,
                    child: SlideTransition(
                      position: _cardSlideAnimation,
                      child: _ForgotPasswordCard(
                        formKey: _formKey,
                        emailController: _emailController,
                        isLoading: _isLoading,
                        fadeAnimation: _cardFadeAnimation ?? const AlwaysStoppedAnimation<double>(1),
                        onBack: _handleBack,
                        onSend: _sendResetEmail,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.width, required this.height, required this.slideAnimation});
  final double width;
  final double height;
  final Animation<Offset> slideAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.orange, AppColors.orangeLight]),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 38,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const _BrandLogo(),
                const SizedBox(height: 2),
                Text('COFFEE • MILKTEA • GOOD VIBES', style: TextStyle(color: Colors.black, fontSize: width < 340 ? 8 : 10, fontWeight: FontWeight.w600, letterSpacing: 0.7)),
              ],
            ),
          ),
          Positioned(
            left: -width * 0.18,
            right: -width * 0.18,
            bottom: 20,
            child: SlideTransition(
              position: slideAnimation,
              child: Image.asset('assets/images/login_drinks.png', height: height * 0.72, fit: BoxFit.contain, semanticLabel: 'Three KKOPI.TEA bubble tea and coffee drinks'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(fontSize: 42, height: 0.95, fontWeight: FontWeight.w900, letterSpacing: -1.5),
        children: [
          TextSpan(text: 'KKOPI', style: TextStyle(color: Colors.white)),
          TextSpan(text: '.TEA', style: TextStyle(color: Colors.black)),
        ],
      ),
    );
  }
}

class _ForgotPasswordCard extends StatelessWidget {
  const _ForgotPasswordCard({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.fadeAnimation,
    required this.onBack,
    required this.onSend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final Animation<double> fadeAnimation;
  final VoidCallback onBack;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(42, 18, 42, 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Form(
        key: formKey,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, color: Colors.black), padding: EdgeInsets.zero),
                  const Expanded(child: Text('Forgot password', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email Address', Icons.email_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter your email address';
                  if (!value.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'NOTE: ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: 'The verification code will send through your email address. If you did not receive one just send another verification code. The code will only applicable within 3 minutes.'),
                  ],
                ),
                style: TextStyle(color: Color(0xFF666666), fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 28),
              Align(
                child: SizedBox(
                  width: 120,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSend,
                    style: _buttonStyle(),
                    child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('SEND', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '© 2026 Kkopitea. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF999999), fontSize: 8, height: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
    prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 22),
    filled: true,
    fillColor: const Color(0xFFF7F7F7),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD8D8D8))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD8D8D8))),
  );
}

ButtonStyle _buttonStyle() {
  return ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)));
}
