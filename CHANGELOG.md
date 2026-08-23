# Journal des modifications

Changements fonctionnels de LTMO, du point de vue de ce que les utilisateurs
voient ou ressentent (pas un historique technique des commits).

## Depuis la version 0.1.2 (build 2)

### Parcours de traitement
- **Date de début manuelle par étape.** Une étape du parcours peut désormais
  démarrer à une date choisie librement, plutôt que d'être automatiquement
  enchaînée au lendemain de la fin de l'étape précédente. Utile quand une
  étape est terminée mais que la suivante ne commence pas tout de suite
  (ex : en attente d'un rendez-vous précis).

### Rappels & notifications
- **Fin des rappels manqués sur Samsung (et appareils similaires).**
  L'application demande maintenant l'autorisation de fonctionner en
  arrière-plan, avec un bouton dédié dans *Réglages > Rappels &
  notifications* si l'autorisation n'a pas été accordée au premier lancement.
- **Fin des notifications en double.** Quand un rappel (médicament ou
  rendez-vous) arrivait à la fois par notification locale et par
  notification push, il pouvait s'afficher deux fois. Un seul rappel
  s'affiche désormais.
- **Chaque téléphone ne reçoit plus que ce qui le concerne.** Les rappels
  locaux respectaient mal le choix "notifier moi / mon-ma partenaire / les
  deux" configuré par traitement ou rendez-vous - c'est corrigé.
- **Rappels fiabilisés pour les prises à jours fixes.** Un bug côté serveur
  empêchait l'envoi de *tous* les rappels (médicaments et rendez-vous) dès
  qu'un médicament était programmé sur des jours spécifiques de la semaine
  (plutôt que tous les jours) - corrigé.

### Médicaments
- **Historique des prises préservé.** Désactiver un médicament ne supprime
  plus définitivement son historique de prises ; il est simplement retiré
  de la liste active, l'historique reste consultable.

### Compte
- **Connexion avec Google** : mise à jour de la configuration suite à un
  changement côté Google Cloud.

### Divers
- Le numéro de version affiché dans l'app (écran d'accueil, profil,
  informations personnelles) correspond désormais exactement à la version
  publiée.
