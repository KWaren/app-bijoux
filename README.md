# Stock Flow

[![Build APK](https://github.com/KWaren/app-bijoux/actions/workflows/build-apk.yml/badge.svg)](https://github.com/KWaren/app-bijoux/actions/workflows/build-apk.yml)

Application mobile de gestion pour petit commerce : stock, ventes, dépenses, clients et suivi des dettes — pensée pour remplacer le duo bloc-notes + Excel par un seul outil, utilisable **hors-ligne**.

## Fonctionnalités

- **Stock / Arrivage** par mois : article, quantité achetée, prix total payé pour le lot (prix de gros) → prix unitaire de détail calculé automatiquement, quantité endommagée, prix de vente max/dernier, photo de l'article
- **Ventes** : choix de l'article → nom du client → date → prix → quantité, avec calcul automatique du stock restant. Le nom du client est enregistré à chaque vente mais il n'y a pas de fiche/historique par client (pas de module Clients séparé)
- **Autres dépenses** : transport, sachets, frais de retrait...
- **Résumé automatique** (jour / semaine / mois) : total des achats, total des ventes, dépenses & pertes, bénéfice (+ marge en %), dettes en cours (ajout et suivi centralisés dans cet écran)
- **Tableau de bord enrichi** : marge en %, bénéfice minimum garanti sur le stock restant (basé sur un prix de vente minimum fixé par article, masqué comme le prix d'achat), articles les plus vendus, évolution des ventes/bénéfices sur 6 mois
- **Export Excel** du rapport de la période sélectionnée, partageable directement (WhatsApp, mail, Drive...)
- **Sauvegarde locale automatique** de la base de données à chaque lancement
- **Prix d'achat masqué par défaut**, pour ne jamais l'afficher par erreur devant un·e client·e
- Fonctionne **entièrement hors-ligne** (base SQLite locale, une seule utilisatrice)

## Stack technique

- [Flutter](https://flutter.dev) / Dart
- `sqflite` — stockage local SQLite
- `provider` — gestion d'état
- `excel` + `share_plus` — export et partage de rapports
- `image_picker` — photos des articles

## Lancer le projet

Les dossiers `android/`/`ios/` ne sont pas versionnés dans ce repo (ils sont régénérés à chaque build, voir plus bas) : il faut donc d'abord les créer avant de pouvoir lancer ou builder l'app en local.

```bash
flutter create --platforms=android --org com.appbijoux.gestion .
flutter pub get
flutter run
```

## Générer un APK

Le workflow GitHub Actions (`.github/workflows/build-apk.yml`) génère automatiquement un APK release à chaque push sur `main` (téléchargeable dans les artefacts de l'action, conservés 90 jours), ou manuellement depuis l'onglet **Actions** → **Run workflow**.

Pour publier une version téléchargeable durablement, pousser un tag `vX.Y.Z` :

```bash
git tag v1.0.0
git push origin v1.0.0
```

Une [Release GitHub](https://github.com/KWaren/app-bijoux/releases) est alors créée automatiquement avec l'APK signé en pièce jointe.

Pour générer un APK en local, après l'étape `flutter create` ci-dessus :

```bash
flutter build apk --release
```

## Tests

```bash
flutter test
```

## Structure du projet

```
lib/
  database/    # accès SQLite + sauvegarde
  models/      # Arrivage, Vente, Dépense, Dette, Résumé
  screens/     # écrans de l'application
  services/    # export Excel
  state/       # état global (Provider)
  widgets/     # composants réutilisables
  theme/       # thème visuel
  utils/       # formatage, périodes
```

## Licence

Ce projet est distribué sous licence MIT — voir le fichier [LICENSE](LICENSE). Libre à toi de le récupérer, l'adapter et l'utiliser pour ton propre commerce.
