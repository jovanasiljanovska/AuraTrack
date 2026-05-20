import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/image_service.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/profile_avatar.dart';

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
    _weightCtrl =
        TextEditingController(text: user?.weightKg?.toStringAsFixed(1) ?? '');
    _heightCtrl =
        TextEditingController(text: user?.heightCm?.toStringAsFixed(0) ?? '');
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
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_hasUnsavedChanges)
            TextButton(
              onPressed: isLoading ? null : _save,
              child: const Text('SAVE'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ProfileAvatar(
                    displayName: _nameCtrl.text.isEmpty
                        ? user.displayName
                        : _nameCtrl.text,
                    photoBase64: _pendingPhotoBase64 ?? user.photoBase64,
                    radius: 60,
                    onTap: isLoading ? null : _pickPhoto,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Display name',
                  prefixIcon: Icons.person_outline,
                  validator: Validators.displayName,
                  enabled: !isLoading,
                  onSubmitted: (_) => _markDirty(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _weightCtrl,
                        label: 'Weight (kg)',
                        prefixIcon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        enabled: !isLoading,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final parsed = double.tryParse(v.replaceAll(',', '.'));
                          if (parsed == null || parsed <= 0 || parsed > 500) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          if (parsed == null || parsed < 50 || parsed > 280) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _ageCtrl,
                  label: 'Age',
                  prefixIcon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  enabled: !isLoading,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final parsed = int.tryParse(v);
                    if (parsed == null || parsed < 5 || parsed > 120) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
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
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: (isLoading || !_hasUnsavedChanges) ? null : _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : () => auth.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}