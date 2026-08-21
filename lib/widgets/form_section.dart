import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Carte blanche à ombre douce regroupant un ensemble de champs sous un
/// intitulé de section (ex: "Identification", "Prix d'achat"), comme dans
/// les formulaires du mockup "Classique".
class FormSection extends StatelessWidget {
  final String titre;
  final List<Widget> children;

  const FormSection({super.key, required this.titre, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSection),
        boxShadow: AppTheme.ombreDouce,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppTheme.bleuMarine,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Tuile de saisie non textuelle (date...) : même fond gris que les
/// `TextFormField` remplis qui l'entourent, pour qu'elle ne flotte pas sur le
/// blanc de la section au milieu des autres champs.
class ChampTuile extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;
  final VoidCallback onTap;

  const ChampTuile({
    super.key,
    required this.icone,
    required this.label,
    required this.valeur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.grisClair,
        borderRadius: BorderRadius.circular(AppTheme.radiusChamp),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusChamp),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.bleuMarine.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icone, size: 16, color: AppTheme.bleuMarine),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(valeur, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFFA8AEB8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloc mis en avant (fond vert) pour une valeur calculée importante, comme
/// le bénéfice minimum garanti estimé dans le formulaire d'arrivage.
class HighlightBox extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;

  const HighlightBox({super.key, required this.icone, required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.beneficeBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.beneficeFg.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icone, size: 16, color: AppTheme.beneficeFg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppTheme.beneficeFg,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valeur,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.beneficeFg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
