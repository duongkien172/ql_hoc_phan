import 'dart:convert';
import 'package:flutter/material.dart';

const kPrimary = Color(0xFF1E4A93);
const kAccent = Color(0xFF2F5BBE);
const kGreen = Color(0xFF2EAD66);
const kRed = Color(0xFFD32F3C);
const kBg = Color(0xFFF3F5F9);

class VkuLogo extends StatelessWidget {
  final double size;
  const VkuLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class GvAvatar extends StatelessWidget {
  final String base64Str;
  final double radius;
  const GvAvatar({super.key, required this.base64Str, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    if (base64Str.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64Decode(base64Str)),
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFDCE4F5),
      child: Icon(Icons.person, color: kPrimary, size: radius),
    );
  }
}