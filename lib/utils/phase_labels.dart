/// Default journey stage types offered when starting a fresh parcours or
/// adding a new step. Modeled after a real antagonist-protocol IVF timeline
/// (clinic protocol sheet, AMP74/CH Alpes-Léman): pre-treatment priming
/// (e.g. Provames) before stimulation even starts, then a mid-stimulation
/// checkpoint where the antagonist is added and the first echo/blood test
/// happens, distinct from the stimulation start itself. Each stage can
/// still be freely renamed, added, removed, or reordered - this list is
/// just the starting scaffold, not a hard requirement.
const List<String> defaultJourneyStageTypes = [
  'preparation',
  'stimulation',
  'controle',
  'declenchement',
  'ponction',
  'transfert',
  'attente_test',
];

String getPhaseLabel(String? type) {
  switch (type) {
    case 'preparation':
      return 'Préparation';
    case 'stimulation':
      return 'Stimulation';
    case 'controle':
      return 'Contrôle & Antagoniste';
    case 'declenchement':
      return 'Déclenchement';
    case 'ponction':
      return 'Ponction';
    case 'transfert':
      return 'Transfert';
    case 'attente_test':
      return 'Attente & Test';
    default:
      return type ?? 'Phase en cours';
  }
}

String getPhaseShort(String type) {
  switch (type) {
    case 'preparation':
      return 'Prépa-\nration';
    case 'stimulation':
      return 'Stim-\nlation';
    case 'controle':
      return 'Contrôle\n& Antag.';
    case 'declenchement':
      return 'Déclen-\nchement';
    case 'ponction':
      return 'Ponc-\ntion';
    case 'transfert':
      return 'Trans-\nfert';
    case 'attente_test':
      return 'Attente\n& Test';
    default:
      return type;
  }
}
