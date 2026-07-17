# LTMO — Application mobile (Flutter)

LTMO est une application mobile en français destinée aux couples en parcours
de PMA (procréation médicalement assistée : FIV, insémination, etc.). Elle
permet aux deux partenaires de coordonner ensemble les rendez-vous médicaux
et les prises de médicaments d'un même traitement.

Le problème résolu : un parcours de PMA implique un planning dense et
changeant d'injections, de comprimés, de prises de sang, d'échographies et
d'interventions, suivi par **deux** personnes. LTMO donne aux deux partenaires
la même vue en temps réel du plan de traitement, avec des rappels envoyés à
l'un, l'autre, ou les deux.

Ce dépôt contient le frontend Flutter (Android / iOS / Web). Le backend
Laravel se trouve dans `pma-backend` (API REST consommée sur
`https://pma.besse.dev/api/v1`).

## Fonctionnalités

- **Compte couple partagé** — deux comptes accèdent aux mêmes données ;
  chaque modification est immédiatement visible par le partenaire
- **Accueil "Aujourd'hui"** — vue du jour : prochains rendez-vous et prises
  de médicaments à valider
- **Agenda** — calendrier des rendez-vous et médicaments, avec ajout,
  édition et compte rendu post-visite
- **Traitements** — gestion des médicaments (dosage, fréquence, horaires)
  et validation des prises (historique)
- **Parcours** — configuration des étapes du parcours PMA (stimulation,
  ponction, transfert…) pour situer le traitement dans le temps
- **Praticiens** — carnet des praticiens liés aux rendez-vous
- **Rappels flexibles** — notifications push (Firebase) et locales, avec
  plusieurs délais de rappel configurables par événement, routées vers un
  partenaire ou les deux
- **Réglages** — préférences de notifications, partage avec le partenaire,
  informations personnelles

## Stack technique

| Domaine | Choix |
|---|---|
| Framework | Flutter (Dart ≥ 3.0) |
| État | Riverpod (`flutter_riverpod` + génération) |
| Navigation | `go_router` (shell avec onglets Accueil / Agenda / Traitements / Profil) |
| HTTP | Dio, tokens Sanctum stockés via `flutter_secure_storage` |
| Hors-ligne | Hive (modèles générés via `build_runner`) |
| Notifications | Firebase Cloud Messaging + `flutter_local_notifications` |
| UI | Google Fonts, Phosphor Icons, `table_calendar` |

## Structure du code

```
lib/
├── models/        # Modèles (User, Couple, Appointment, Medication, JourneyStage…) + adaptateurs Hive
├── providers/     # Providers Riverpod (auth, rendez-vous, médicaments, parcours…)
├── screens/       # Écrans par domaine (auth, home, agenda, medications, journey, settings…)
├── services/      # ApiService (Dio), notifications push/locales, stockage
├── navigation/    # Routes go_router
├── widgets/       # Composants réutilisables (formulaires, cartes, badges…)
├── theme/         # Couleurs, typographie, thème LTMO
└── utils/         # Constantes, libellés de phases, calcul des échéances
```

## Démarrage

```bash
flutter pub get
flutter run
```

Après modification des modèles Hive ou des providers annotés :

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Configuration requise

- **`android/app/google-services.json`** — config Firebase Android,
  volontairement non versionnée (`.gitignore`). À récupérer depuis la
  console Firebase. En CI, elle est injectée depuis le secret
  `GOOGLE_SERVICES_JSON_BASE64`.
- **`android/key.properties`** — keystore de signature pour les builds
  release Android (non versionné).
- **URL de l'API** — définie dans `lib/services/api_service.dart`
  (`ApiService.baseUrl`).

## Builds

```bash
flutter build apk --release        # APK Android
flutter build appbundle --release  # App Bundle Android
flutter build ipa --release        # iOS
flutter build web --release        # Web
```

### CI

Le workflow GitHub Actions [build-apks.yml](.github/workflows/build-apks.yml)
construit les APK debug et release à chaque push sur `main`. Le numéro de
run CI sert de version affichée dans l'app (écran de démarrage et réglages),
et l'intégrité du keystore est vérifiée avant le build release.

## Tests

```bash
flutter test
```
