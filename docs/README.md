# Documentation EEDS / E-Gàlle

Adaptation de [hitobito](https://github.com/hitobito/hitobito) (gestionnaire de
membres de la fédération scoute suisse) au contexte des **Éclaireuses et
Éclaireurs du Sénégal**, sous la marque **E-Gàlle**.

## Sommaire

1. [Architecture](architecture.md) — les 3 dépôts, l'ordre de chargement
   des wagons, le rôle de chaque composant.
2. [Workflow de développement](workflow.md) — Docker, ports, commandes
   `wagon:migrate`, `wagon:seed`, debug, reset DB.
3. [Modèle Person — adaptations EEDS](person.md) — nouveaux champs, validations,
   PUBLIC_ATTRS / permitted_attrs / SEARCHABLE / FILTER, locales FR.
4. [Groupes et rôles](groups-and-roles.md) — `Group::Subgroup`, hiérarchie
   EEDS (Bund / Région / District / Groupe local / Unité / Sous-groupe),
   correspondance avec les types PBS d'origine.
5. [Branches de progression](branches.md) — Jiwu / Lawtan / Toor-Toor / Mennef,
   modélisation via `QualificationKind` (IDs 1001–1004).
6. [Divergences vs upstream](divergences.md) — liste exhaustive de ce qui change
   par rapport à `hitobito` + `hitobito_pbs` upstream ; à lire avant tout
   merge ou rebase.

## Pour qui ?

- **Nouveaux contributeurs** : commencer par [Architecture](architecture.md)
  puis [Workflow](workflow.md).
- **Mainteneur upstream sync** : lire [Divergences](divergences.md).
- **Reprise de session** : voir le plan à jour dans
  `~/.copilot/session-state/.../plan.md` (hors repo, par session de travail).
