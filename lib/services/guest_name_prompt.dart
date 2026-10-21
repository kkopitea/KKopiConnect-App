import 'package:flutter/material.dart';

import '../app_colors.dart';

Future<String?> showGuestNamePrompt(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _GuestNameDialog(),
  );
}

class _GuestNameDialog extends StatefulWidget {
  const _GuestNameDialog();

  @override
  State<_GuestNameDialog> createState() => _GuestNameDialogState();
}

class _GuestNameDialogState extends State<_GuestNameDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Material(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                  decoration: const BoxDecoration(
                    gradient: AppColors.orangeGradient,
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.local_cafe_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'KKOPI.TEA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'COFFEE  •  MILKTEA  •  GOOD VIBES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'What name should we use?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We’ll use this name for your guest orders.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _controller,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          maxLength: 80,
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            labelText: 'Name for your orders',
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.orange,
                            ),
                            filled: true,
                            fillColor: AppColors.inputFill,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.orange,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) return 'Please enter your name.';
                            if (name.length > 80) {
                              return 'Name must be 80 characters or less.';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.orange,
                                  minimumSize: const Size.fromHeight(48),
                                  side: const BorderSide(
                                    color: AppColors.orange,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orange,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
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
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }
}
