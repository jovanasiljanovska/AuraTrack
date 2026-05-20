import 'dart:convert';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.displayName,
    this.photoBase64,
    this.radius = 40,
    this.onTap,
  });

  final String displayName;
  final String? photoBase64;
  final double radius;
  final VoidCallback? onTap;

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoBase64 != null && photoBase64!.isNotEmpty;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage:
      hasPhoto ? MemoryImage(base64Decode(photoBase64!)) : null,
      child: hasPhoto
          ? null
          : Text(
        _initials,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );

    if (onTap != null) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.camera_alt,
                      size: radius * 0.4,
                      color: colorScheme.onPrimary),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }
}