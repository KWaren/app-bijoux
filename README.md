# App Bijoux

Application mobile de gestion pour un petit business de bijoux : stock, ventes, dépenses, clients et suivi des dettes — pensée pour remplacer le duo bloc-notes + Excel par un seul outil, utilisable **hors-ligne**.

## Fonctionnalités

- **Stock / Arrivage** par mois : modèle, quantité, prix d'achat unitaire, quantité endommagée, prix de vente max/dernier, photo du modèle
- **Ventes** : choix du modèle → client → date → prix → quantité, avec calcul automatique du stock restant
- **Autres dépenses** : transport, sachets, frais de retrait...
- **Résumé automatique** (jour / semaine / mois) : total des achats, total des ventes, dépenses & pertes, bénéfice
- **Clients** : historique d'achats par client, suivi des dettes et paiements partiels
- **Export Excel** du rapport de la période sélectionnée, partageable directement (WhatsApp, mail, Drive...)
- **Sauvegarde locale automatique** de la base de données à chaque lancement
- **Prix d'achat masqué par défaut**, pour ne jamais l'afficher par erreur devant un·e client·e
- Fonctionne **entièrement hors-ligne** (base SQLite locale, une seule utilisatrice)

## Stack technique

- [Flutter](https://flutter.dev) / Dart
- `sqflite` — stockage local SQLite
- `provider` — gestion d'état
- `excel` + `share_plus` — export et partage de rapports
- `image_picker` — photos des modèles

## Lancer le projet

```bash
flutter pub get
flutter run
```

## Générer un APK

Le workflow GitHub Actions (`.github/workflows/build-apk.yml`) génère automatiquement un APK release à chaque push sur `main` (téléchargeable dans les artefacts de l'action), ou manuellement depuis l'onglet **Actions** → **Run workflow**.

Pour générer un APK en local, il faut d'abord ajouter la scaffolding Android (non versionnée dans ce repo) :

```bash
flutter create --platforms=android --org com.appbijoux.gestion .
flutter build apk --release
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

Ce projet est distribué sous licence MIT — voir le fichier [LICENSE](LICENSE). Libre à toi de le récupérer, l'adapter et l'utiliser pour ton propre business.
