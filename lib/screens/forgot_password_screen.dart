import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  static const orange = AppColors.orange;

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
      Navigator.pop(context);
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
    _emailController.dispose();
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
                    padding: const EdgeInsets.fromLTRB(36, 14, 36, 42),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration('Email Address', Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email address';
                              }
                              if (!value.contains('@')) return 'Please enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'NOTE: ', style: TextStyle(fontWeight: FontWeight.w800)),
                                TextSpan(text: 'The verification code will send through your email address. If you did not receive one just send another verification code. The code will only applicable within 3 minutes.'),
                              ],
                            ),
                            style: TextStyle(color: Color(0xFF666666), fontSize: 12, height: 1.7),
                          ),
                          const SizedBox(height: 42),
                          Align(
                            child: SizedBox(
                              width: 120,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sendResetEmail,
                                style: _buttonStyle(),
                                child: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('SEND', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 100),
                          const Text(
                            '© 2026 Kkopitea. All rights reserved. Unauthorized reproduction or\ndistribution is strictly prohibited.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF999999), fontSize: 8, height: 2),
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
        const Expanded(child: Text('Forgot password', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        const SizedBox(width: 48),
      ],
    );
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
    return ElevatedButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white, elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)));
  }
}
