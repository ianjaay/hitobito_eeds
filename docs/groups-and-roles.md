# Groupes et rôles EEDS

## Hiérarchie EEDS

Les niveaux hiérarchiques EEDS réutilisent les types `Group::*` définis par
`hitobito_pbs`, **renommés en français** via les locales (cf. fork
`hitobito_pbs` branche `eeds-customizations`). En interne le code Ruby
manipule encore les noms PBS (équivalents allemands), c'est uniquement
l'affichage qui change.

| Affichage EEDS (FR) | Classe Ruby (PBS) | Layer ? |
|---|---|---|
| **Fédération (EEDS)** | `Group::Bund` | oui |
| **Région EEDS** | `Group::Kantonalverband` (souvent abrégé `kv`) | oui |
| **District** | `Group::Region` | oui |
| **Groupe local** | `Group::Abteilung` | oui |
| **Unité — Mbotaay** (louveteaux) | `Group::Woelfe` | non |
| **Unité — Kayon** (éclais) | `Group::Pfadi` | non |
| **Unité — Ñawka** (pionniers) | `Group::Pio` | non |
| **Unité — Gàlle** (routiers) | `Group::Rover` | non |
| **Sous-groupe** (équipe / patrouille / sizaine) | `Group::Subgroup` ← **EEDS** | non |

> Note : « Région EEDS » (scoute) ≠ « Région administrative » (champ Person
> avec les 14 régions du Sénégal). Voir [Person](person.md).

## `Group::Subgroup` — type EEDS

Fichier : `app/models/group/subgroup.rb`

```ruby
class Group::Subgroup < Group
  self.layer = false      # hérite des permissions de l'unité parente
  children                # terminal : pas de sous-sous-groupe

  class Leader < ::Role
    self.permissions = [:group_read]
    self.kind = :member
  end

  class Member < ::Role
    self.permissions = [:group_read]
    self.kind = :member
  end

  roles Leader, Member
  self.standard_role = Member
end
```

### Wiring : où peut-on créer un sous-groupe ?

Dans `lib/hitobito_eeds/wagon.rb#to_prepare` :

```ruby
[Group::Woelfe, Group::Pfadi, Group::Pio, Group::Rover].each do |unit|
  unit.children(Group::Subgroup) unless unit.possible_children.include?(Group::Subgroup)
end
Role.reset_types!
```

→ chaque type d'unité (Mbotaay/Kayon/Ñawka/Gàlle) peut accueillir des
sous-groupes. Pas besoin de migration : `Group` étant en single-table
inheritance, un nouveau type ne change pas le schéma.

### Locale FR

```yaml
# config/locales/groups.eeds.fr.yml
fr:
  activerecord:
    models:
      group/subgroup: "Sous-groupe (équipe / patrouille / sizaine)"
      group/subgroup/leader: "Animateur·trice de sous-groupe"
      group/subgroup/member: "Membre"
```

## Pourquoi pas un nouveau modèle ?

L'approche envisagée (Option A) consistait à créer une table `subgroups`
séparée. Rejetée au profit de l'Option B (sous-classer `Group`) parce que :

- Hiérarchie, permissions, soft-delete, événements, exports, recherche :
  **tout est gratuit** si on reste dans `Group`.
- L'UI d'ajout de membre = formulaire d'attribution de rôle standard
  (zéro vue custom à maintenir).
- Cohérent avec la stratégie PBS (chaque niveau scout = un sous-type
  `Group`).
