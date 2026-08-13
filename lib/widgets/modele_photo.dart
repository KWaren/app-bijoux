import 'dart:io';

import 'package:flutter/material.dart';

class ModelePhoto extends StatelessWidget {
  final String? photoPath;
  final double taille;

  const ModelePhoto({super.key, required this.photoPath, this.taille = 48});

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: (path != null && File(path).existsSync())
          ? Image.file(File(path), width: taille, height: taille, fit: BoxFit.cover)
          : Container(
              width: taille,
              height: taille,
              color: colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.diamond_outlined, size: taille * 0.5, color: colorScheme.primary),
            ),
    );
  }
}
