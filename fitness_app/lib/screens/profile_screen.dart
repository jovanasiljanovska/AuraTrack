import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/image_service.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/profile_avatar.dart';
import '../../models/app_user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageService = ImageService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _ageCtrl;
  String? _gender;
  String? _pendingPhotoBase64;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().appUser;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _weightCtrl = TextEditingController(
        text: user?.weightKg?.toStringAsFixed(1) ?? '');
    _heightCtrl = TextEditingController(
        text: user?.heightCm?.toStringAsFixed(0) ?? '');
    _ageCtrl = TextEditingController(text: user?.age?.toString() ?? '');
    _gender = user?.gender;

    for (final c in [_nameCtrl, _weightCtrl, _heightCtrl, _ageCtrl]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource_>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource_.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource_.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final base64 =
      await _imageService.pickAndCompressAsBase64(source: source);
      if (base64 == null) return;
      setState(() {
        _pendingPhotoBase64 = base64;
        _hasUnsavedChanges = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load image: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      displayName: _nameCtrl.text.trim(),
      photoBase64: _pendingPhotoBase64,
      weightKg: double.tryParse(_weightCtrl.text.replaceAll(',', '.')),
      heightCm: double.tryParse(_heightCtrl.text),
      age: int.tryParse(_ageCtrl.text),
      gender: _gender,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Profile updated'
            : auth.errorMessage ?? 'Could not save changes'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) {
      setState(() {
        _pendingPhotoBase64 = null;
        _hasUnsavedChanges = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.appUser;
    final isLoading = auth.isLoading;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: CustomScrollView(
        slivers: [
          // ---------- Hero header ----------
          SliverToBoxAdapter(
            child: _ProfileHero(
              user: user,
              pendingPhotoBase64: _pendingPhotoBase64,
              displayName: _nameCtrl.text.isEmpty
                  ? user.displayName
                  : _nameCtrl.text,
              isLoading: isLoading,
              onAvatarTap: isLoading ? null : _pickPhoto,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ),

          // ---------- Personal info section ----------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _sectionLabel('PERSONAL INFO'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _Card(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _nameCtrl,
                        label: 'Display name',
                        prefixIcon: Icons.person_outline,
                        validator: Validators.displayName,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _weightCtrl,
                              label: 'Weight (kg)',
                              prefixIcon: Icons.monitor_weight_outlined,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                              enabled: !isLoading,
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final parsed =
                                double.tryParse(v.replaceAll(',', '.'));
                                if (parsed == null ||
                                    parsed <= 0 ||
                                    parsed > 500) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTextField(
                              controller: _heightCtrl,
                              label: 'Height (cm)',
                              prefixIcon: Icons.height,
                              keyboardType: TextInputType.number,
                              enabled: !isLoading,
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final parsed = int.tryParse(v);
                                if (parsed == null ||
                                    parsed < 50 ||
                                    parsed > 280) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _ageCtrl,
                        label: 'Age',
                        prefixIcon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        enabled: !isLoading,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final parsed = int.tryParse(v);
                          if (parsed == null ||
                              parsed < 5 ||
                              parsed > 120) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.wc),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'female', child: Text('Female')),
                          DropdownMenuItem(
                              value: 'other', child: Text('Other')),
                          DropdownMenuItem(
                              value: 'prefer_not_to_say',
                              child: Text('Prefer not to say')),
                        ],
                        onChanged: isLoading
                            ? null
                            : (value) {
                          setState(() {
                            _gender = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---------- Save button ----------
          if (_hasUnsavedChanges)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Save changes'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ---------- Account section ----------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _sectionLabel('ACCOUNT'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _Card(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AccountRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                      iconColor: const Color(0xFF4A90E2),
                    ),
                    const Divider(height: 1, indent: 56),
                    _AccountRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member since',
                      value: _formatJoinDate(user.createdAt),
                      iconColor: const Color(0xFF7B61FF),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------- Sign out ----------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign out?'),
                        content: const Text(
                            'You\'ll need to sign in again to access your data.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) auth.signOut();
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _formatJoinDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ============== Hero ==============

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.pendingPhotoBase64,
    required this.displayName,
    required this.isLoading,
    required this.onAvatarTap,
    required this.onBack,
  });

  final AppUser user;
  final String? pendingPhotoBase64;
  final String displayName;
  final bool isLoading;
  final VoidCallback? onAvatarTap;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack,
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Spacer for symmetry with back button
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ProfileAvatar(
              displayName: displayName,
              photoBase64: pendingPhotoBase64 ?? user.photoBase64,
              radius: 50,
              onTap: onAvatarTap,
            ),
            const SizedBox(height: 14),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ============== Reusable card ==============

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============== Account row ==============

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}