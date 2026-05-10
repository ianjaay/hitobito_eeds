# hitobito_eeds

Adaptation Hitobito pour les **Éclaireuses et Éclaireurs du Sénégal** (E-Gàlle).

Ce wagon ajoute les spécificités EEDS par-dessus `hitobito_pbs` :

- Nouveaux attributs Person (lieu de naissance, nationalité, région administrative,
  contact d'urgence)
- Nouveau type de groupe `Group::Subgroup` (équipe / patrouille / sizaine)
- Branches de progression scoute (Jiwu / Lawtan / Toor-Toor / Mennef) via Qualifications
- Labels FR/Sénégal pour téléphones, social, scolarité

## Activation

Le Wagonfile auto-détecte tous les `app/hitobito_*/` ou utiliser :

```bash
WAGONS="youth pbs eeds" bundle exec rails server
```
