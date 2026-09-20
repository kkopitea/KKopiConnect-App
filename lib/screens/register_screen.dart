import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'main_interface_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  static const orange = AppColors.orange;

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 2400),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBrandHeader(),
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(36, 14, 36, 34),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 18),
                          _field(_nameController, 'Full Name', Icons.person_outline, validator: _required),
                          const SizedBox(height: 14),
                          _field(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email'),
                          const SizedBox(height: 14),
                          _field(_phoneController, 'Phone number', Icons.phone_android_outlined, keyboardType: TextInputType.phone, validator: _required),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF888888)),
                              ),
                            ),
                            validator: (value) => value != null && value.length >= 6 ? null : 'Use at least 6 characters',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(value: _acceptedTerms, activeColor: orange, onChanged: (value) => setState(() => _acceptedTerms = value ?? false)),
                              const Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: 'I agree to the '), TextSpan(text: 'Terms & Conditions', style: TextStyle(color: orange, fontWeight: FontWeight.w800))]), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: _buttonStyle(),
                              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ', style: TextStyle(fontSize: 11)),
                              GestureDetector(onTap: () => Navigator.pop(context), child: const Text('Log in', style: TextStyle(color: orange, fontSize: 11, fontWeight: FontWeight.w800))),
                            ],
                          ),
                        ],
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

  Widget _buildBrandHeader() {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login_drinks.png', fit: BoxFit.cover),
          Container(color: orange.withValues(alpha: 0.92)),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('KKOPI.TEA', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
              Text('COFFEE · MILKTEA · GOOD VIBES', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.black), padding: EdgeInsets.zero),
        const Expanded(child: Text('Create an account', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        const SizedBox(width: 48),
      ],
    );
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
    return ElevatedButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white, elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)));
  }
}
