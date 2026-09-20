import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'forgot_password_screen.dart';
import 'main_interface_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainInterfaceScreen()));
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'invalid-credential' => 'Incorrect email or password.',
        'invalid-email' => 'Please enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        _ => 'Unable to login. Please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong. Please try again.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight = (constraints.maxHeight * 0.45).clamp(320.0, 390.0);
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: SizedBox(
                height: heroHeight + 470,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _HeroHeader(width: constraints.maxWidth, height: heroHeight),
                    Positioned(
                      top: heroHeight - 30,
                      left: 0,
                      right: 0,
                      child: _LoginCard(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        isLoading: _isLoading,
                        onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                        onLogin: _login,
                        onForgotPassword: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        onRegister: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.width, required this.height});
  final double width;
  final double height;

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
            bottom: -48,
            child: Image.asset('assets/images/login_drinks.png', height: height * 0.72, fit: BoxFit.contain, semanticLabel: 'Three KKOPI.TEA bubble tea and coffee drinks'),
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

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.formKey, required this.emailController, required this.passwordController, required this.obscurePassword, required this.isLoading, required this.onTogglePassword, required this.onLogin, required this.onForgotPassword, required this.onRegister});
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(42, 24, 42, 30),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome!', style: TextStyle(fontSize: 25, height: 1, fontWeight: FontWeight.w900, color: Colors.black)),
            const SizedBox(height: 5),
            const Text('Log in to continue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black)),
            const SizedBox(height: 20),
            AuthTextField(
              controller: emailController,
              hintText: 'Username or email',
              leadingIcon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Enter your username or email';
                if (!value.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 18),
            AuthTextField(
              controller: passwordController,
              hintText: 'Password',
              leadingIcon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onLogin(),
              trailing: Semantics(
                button: true,
                label: obscurePassword ? 'Show password' : 'Hide password',
                child: IconButton(onPressed: onTogglePassword, icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), color: AppColors.iconMuted, tooltip: obscurePassword ? 'Show password' : 'Hide password'),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your password';
                if (value.length < 6) return 'Use at least 6 characters';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onForgotPassword, style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: EdgeInsets.zero), child: const Text('Forgot password?', style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Log in', isLoading: isLoading, onPressed: onLogin),
            const SizedBox(height: 42),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(fontSize: 11, color: Color(0xFF1A1A1A))),
                  GestureDetector(onTap: onRegister, child: const Text('Register', style: TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w800))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({super.key, required this.controller, required this.hintText, required this.leadingIcon, this.trailing, this.obscureText = false, this.keyboardType, this.textInputAction, this.onSubmitted, this.validator});
  final TextEditingController controller;
  final String hintText;
  final IconData leadingIcon;
  final Widget? trailing;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
        prefixIcon: Icon(leadingIcon, color: AppColors.iconMuted, size: 22),
        suffixIcon: trailing,
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.orange, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE53935))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.isLoading, required this.onPressed});
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.6), foregroundColor: Colors.white, elevation: 4, shadowColor: Colors.black45, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
        child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
