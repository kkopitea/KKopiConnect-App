import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'main_interface_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
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
    _cardSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(cardCurve);
    _imageSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.24), end: Offset.zero).animate(cardCurve);
    _cardFadeAnimation = Tween<double>(begin: 0, end: 1).animate(cardCurve);
    _cardController.forward();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Terms & Conditions.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await credential.user?.updateDisplayName(_nameController.text.trim());
      final user = credential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': _emailController.text.trim(),
          'isActive': true,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainInterfaceScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'email-already-in-use' => 'An account already exists for this email.',
        'invalid-email' => 'Please enter a valid email address.',
        'weak-password' => 'Please choose a stronger password.',
        _ => 'Unable to create your account.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBack() async {
    if (_isLeaving) return;
    _isLeaving = true;
    await _cardController.reverse();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _cardController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                    child: _RegisterCard(
                      formKey: _formKey,
                      nameController: _nameController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      acceptedTerms: _acceptedTerms,
                      isLoading: _isLoading,
                      fadeAnimation: _cardFadeAnimation ?? const AlwaysStoppedAnimation<double>(1),
                      onBack: _handleBack,
                      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                      onAcceptedTermsChanged: (value) => setState(() => _acceptedTerms = value),
                      onRegister: _register,
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

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.obscurePassword,
    required this.acceptedTerms,
    required this.isLoading,
    required this.fadeAnimation,
    required this.onBack,
    required this.onTogglePassword,
    required this.onAcceptedTermsChanged,
    required this.onRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool acceptedTerms;
  final bool isLoading;
  final Animation<double> fadeAnimation;
  final VoidCallback onBack;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onAcceptedTermsChanged;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(42, 18, 42, 10),
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
                const Expanded(child: Text('Create an account', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            _field(nameController, 'Full Name', Icons.person_outline, validator: _required),
            const SizedBox(height: 14),
            _field(emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email'),
            const SizedBox(height: 14),
            _field(phoneController, 'Phone number', Icons.phone_android_outlined, keyboardType: TextInputType.phone, validator: _required),
            const SizedBox(height: 14),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(onPressed: onTogglePassword, icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF888888))),
              ),
              validator: (value) => value != null && value.length >= 6 ? null : 'Use at least 6 characters',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(value: acceptedTerms, activeColor: AppColors.orange, onChanged: (value) => onAcceptedTermsChanged(value ?? false)),
                const Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: 'I agree to the '), TextSpan(text: 'Terms & Conditions', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800))]), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: isLoading ? null : onRegister,
                style: _buttonStyle(),
                child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ', style: TextStyle(fontSize: 11)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Log in', style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _field(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, String? Function(String?)? validator}) {
  return TextFormField(controller: controller, keyboardType: keyboardType, decoration: _inputDecoration(hint, icon), validator: validator);
}

String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;

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
