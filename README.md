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

## Documentation complète

Voir [`docs/`](docs/README.md) :

- [Architecture](docs/architecture.md) — les 3 dépôts, ordre de chargement
- [Workflow](docs/workflow.md) — Docker, ports, `wagon:migrate`, `wagon:seed`
- [Person](docs/person.md) — nouveaux champs, validations, locales
- [Groupes et rôles](docs/groups-and-roles.md) — `Group::Subgroup`, hiérarchie
- [Branches de progression](docs/branches.md) — Jiwu / Lawtan / Toor-Toor / Mennef
- [Divergences vs upstream](docs/divergences.md) — à lire avant tout merge
