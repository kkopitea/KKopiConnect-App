import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_colors.dart';
import '../data/payment_method_repository.dart';
import '../services/cloudinary_service.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'login_screen_redesign.dart';
import 'notifications_screen.dart';
import 'order_list_screen.dart';
import 'terms_conditions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onNavigateTab});

  final ValueChanged<int>? onNavigateTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _paymentMethod = 'Pay At The Counter';
  bool _isUploadingPhoto = false;
  Uint8List? _profilePhotoBytes;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _displayNameFor(user);
    final email = user?.email ?? 'No email address';
    final items = [
      ('My Orders', Icons.receipt_long_rounded),
      ('Payment Methods', Icons.wallet_rounded),
      ('Favorites', Icons.favorite_border_rounded),
      ('Notifications', Icons.notifications_none_rounded),
      ('Help & Support', Icons.help_outline_rounded),
      ('Terms & Conditions', Icons.description_outlined),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 2400),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  color: AppColors.orange,
                  child: const Text(
                    'Settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: user == null
                            ? null
                            : FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .snapshots(),
                        builder: (context, snapshot) {
                          final profile = snapshot.data?.data();
                          final name = profile?['name'] is String
                              ? (profile!['name'] as String).trim()
                              : '';
                          final photoUrl = profile?['photoUrl'] as String? ??
                              user?.photoURL;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE8E8E8),
                              ),
                            ),
                            child: Row(
                              children: [
                                _AccountAvatar(
                                  photoUrl: photoUrl,
                                  imageBytes: _profilePhotoBytes,
                                  isUploading: _isUploadingPhoto,
                                  onTap: _pickProfilePhoto,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.isEmpty ? displayName : name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      for (final item in items) ...[
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          leading: Icon(item.$2, color: AppColors.orange),
                          title: Text(
                            item.$1,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: _subtitleFor(item.$1),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF666666),
                          ),
                          onTap: () => _handleMenuTap(context, item.$1),
                        ),
                        const Divider(height: 1, color: Color(0xFFE9E9E9)),
                      ],
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: _logOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayNameFor(User? user) {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    }
    return 'Your account';
  }

  Widget? _subtitleFor(String title) => switch (title) {
    'Payment Methods' => Text(_paymentMethod),
    _ => null,
  };

  Future<void> _handleMenuTap(BuildContext context, String title) async {
    switch (title) {
      case 'My Orders':
        if (widget.onNavigateTab != null) {
          widget.onNavigateTab!(3);
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OrderListScreen()),
          );
        }
        return;
      case 'Payment Methods':
        await _selectPaymentMethod(context);
        return;
      case 'Favorites':
        await _showFavorites(context);
        return;
      case 'Notifications':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NotificationsScreen(
              onNavigateTab: widget.onNavigateTab,
              selectedTab: 4,
            ),
          ),
        );
        return;
      case 'Help & Support':
        await _showHelp(context);
        return;
      case 'Terms & Conditions':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TermsConditionsScreen(
              onNavigateTab: widget.onNavigateTab,
              selectedTab: 4,
            ),
          ),
        );
        return;
    }
  }

  Future<void> _selectPaymentMethod(BuildContext context) async {
    var selectedMethod = _paymentMethod;
    final method = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Payment Methods'),
          content: StreamBuilder(
            stream: PaymentMethodRepository().watchActive(),
            builder: (context, snapshot) {
              final List<String> options = snapshot.hasData
                  ? snapshot.data!.map((method) => method.name).toList()
                  : const ['Pay At The Counter', 'Gcash'];
              return RadioGroup<String>(
                groupValue: selectedMethod,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedMethod = value);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (snapshot.hasError)
                      const Text('Payment methods could not be loaded.')
                    else if (snapshot.hasData && options.isEmpty)
                      const Text('No payment methods are currently available.')
                    else
                      for (final option in options)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(option),
                          value: option,
                          activeColor: AppColors.orange,
                        ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selectedMethod),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (method != null && mounted) setState(() => _paymentMethod = method);
  }

  Future<void> _showFavorites(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FavoritesScreen(
          onNavigateTab: widget.onNavigateTab,
          onBrowseMenu: () {
            Navigator.of(context).pop();
            if (widget.onNavigateTab case final navigate?) {
              navigate(1);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CategoriesScreen(),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _showHelp(BuildContext context) async {
    final viewOrders = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For help with a recent purchase, review the status in My Orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('View orders'),
          ),
        ],
      ),
    );
    if (viewOrders == true && context.mounted) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const OrderListScreen()));
    }
  }

  Future<void> _logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to log out: ${error.message ?? 'Please try again.'}',
          ),
        ),
      );
    }
  }

  Future<void> _pickProfilePhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (image == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final imageBytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _profilePhotoBytes = imageBytes);

      final result = await CloudinaryService().uploadImage(image);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Please sign in to update your photo.');
      }
      await user.updatePhotoURL(result.secureUrl);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': result.secureUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.reload();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update photo: $error')));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({
    required this.photoUrl,
    required this.imageBytes,
    required this.isUploading,
    required this.onTap,
  });

  final String? photoUrl;
  final Uint8List? imageBytes;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();
    final Widget avatar;
    if (imageBytes != null) {
      avatar = ClipOval(
        child: Image.memory(
          imageBytes!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
        ),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
        ),
      );
    } else {
      avatar = _fallbackAvatar();
    }

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          Positioned.fill(child: avatar),
          Positioned(
            right: 0,
            bottom: 0,
            child: Tooltip(
              message: 'Change profile photo',
              child: Material(
                color: AppColors.orange,
                shape: const CircleBorder(
                  side: BorderSide(color: Colors.white, width: 2),
                ),
                child: InkWell(
                  onTap: isUploading ? null : onTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: Center(
                      child: isUploading
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE2BD),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.orange,
        size: 32,
      ),
    );
  }
}
