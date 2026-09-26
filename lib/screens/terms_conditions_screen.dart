import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../widgets/curved_content_page.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const _sections = [
    (
      '1. Using KKOPI.TEA',
      'By creating an account or placing an order through KKOPI.TEA, you agree to these terms. Please do not use the app if you do not agree. You must be legally able to enter into this agreement in your location.',
    ),
    (
      '2. Your account',
      'Keep your sign-in details secure and make sure the information on your account is accurate. You are responsible for activity carried out through your account. Contact us through the selected branch if you believe someone else has accessed it.',
    ),
    (
      '3. Menu and prices',
      'Menu items, ingredients, prices, promotions, and availability may vary by branch and may change without notice. Product images are illustrative. The price shown when you submit an order is the price applicable to that order, subject to confirmation by the selected branch.',
    ),
    (
      '4. Orders and payment',
      'Review your items, customizations, fulfillment method, branch, and payment method before submitting an order. An order request is not accepted until it is confirmed by the branch. Payment is due using the method selected in the app and any instructions provided by the branch.',
    ),
    (
      '5. Pickup, fulfillment, and changes',
      'Follow the pickup or fulfillment details shown for your order. Preparation times are estimates and can change during busy periods. Contact the branch promptly if an order detail is incorrect. An order marked Pending may be cancelled from the app; once preparation has started, cancellation or changes may not be possible.',
    ),
    (
      '6. Profile photos and submitted content',
      'You may choose to upload a profile photo. Only upload images you have permission to use. Do not upload unlawful, harmful, or infringing material. Your selected photo is stored by our image-hosting provider and its URL is associated with your account so it can be displayed in the app.',
    ),
    (
      '7. Privacy and service providers',
      'The app uses account and order information to provide sign-in, process and display orders, and support app features. Authentication and order data are handled by the service providers configured for the app, and uploaded images are hosted by Cloudinary. Those providers process data under their own terms and privacy practices.',
    ),
    (
      '8. Availability and acceptable use',
      'We may update, suspend, or discontinue app features to maintain or improve the service. Do not interfere with the app, attempt unauthorized access, misuse another person’s account, or use the service for unlawful activity.',
    ),
    (
      '9. Limitations',
      'The app is provided on an availability basis. To the extent permitted by applicable law, KKOPI.TEA is not responsible for indirect losses arising from temporary service interruptions, inaccurate third-party information, or events outside our reasonable control. Nothing in these terms limits rights that cannot legally be limited.',
    ),
    (
      '10. Changes and questions',
      'These terms may be updated as the app or its services change. Continued use after updated terms are made available means you accept the revised terms. For questions about an order, contact the branch selected for that order.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CurvedContentPage(
      title: 'Terms & Conditions',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: [
          const Text(
            'KKOPI.TEA App Terms',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please read these terms before using the app or placing an order.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          for (final section in _sections) ...[
            Text(
              section.$1,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              section.$2,
              style: const TextStyle(
                color: Color(0xFF424242),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}
