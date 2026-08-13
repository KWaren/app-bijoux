import 'dart:io';

import 'package:flutter/material.dart';

class ModelePhoto extends StatelessWidget {
  final String? photoPath;
  final double taille;

  const ModelePhoto({super.key, required this.photoPath, this.taille = 48});

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: (path != null && File(path).existsSync())
          ? Image.file(File(path), width: taille, height: taille, fit: BoxFit.cover)
          : Container(
              width: taille,
              height: taille,
              color: const Color(0xFFE3D5B8),
              child: Icon(Icons.diamond_outlined, size: taille * 0.5, color: const Color(0xFF9C7A1E)),
            ),
    );
  }
}
