import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ClassicNavItem {
  final IconData icone;
  final String label;

  const ClassicNavItem({required this.icone, required this.label});
}

/// Barre de navigation basse plate (icône + libellé, sans pastille
/// derrière l'icône sélectionnée), conforme au mockup "Classique".
class ClassicBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ClassicNavItem> items;

  const ClassicBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: AppTheme.bleuMarineFonce.withValues(alpha: 0.06), offset: const Offset(0, -6), blurRadius: 16),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  selectionne: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final ClassicNavItem item;
  final bool selectionne;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selectionne, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final couleur = selectionne ? AppTheme.bleuMarine : const Color(0xFFA8AEB8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icone, size: 22, color: couleur),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: couleur,
                fontWeight: selectionne ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
