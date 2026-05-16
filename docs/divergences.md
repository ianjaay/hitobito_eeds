# Divergences vs upstream

Ce document recense ce qui diverge entre :

- `hitobito` core upstream
- `hitobito_pbs` upstream
- la version EEDS effectivement déployée (fork `hitobito_pbs` branche
  `eeds-customizations` + wagon `hitobito_eeds`)

**À lire avant tout merge / rebase upstream.**

## Wagon `hitobito_eeds` (greenfield)

Ce wagon est entièrement EEDS, aucun équivalent upstream. Voir [Person](person.md),
[Groupes](groups-and-roles.md), [Branches](branches.md).

## Fork `hitobito_pbs` — branche `eeds-customizations`

Commits divergents (au-dessus de `upstream/master`) :

| Commit | Résumé | Catégorie |
|---|---|---|
| `ec852e02` | EEDS: adaptation hitobito_pbs pour Éclaireurs et Éclaireuses du Sénégal | Base FR/SN (gros patch initial) |
| `4fcd5b19` | EEDS: visibilité membres, langue défaut FR, cascade soft-delete | Comportement |
| `34017f74` | EEDS: traduire en FR les libellés de rôles restés en allemand | Locales |
| `ab88da7b` | EEDS: scan FR — finir de traduire/adapter au contexte EEDS | Locales |
| `9a0ce1c9` | EEDS Phase 3: relabéliser pbs_number, kv, pronouns en FR | Locales |
| `ec028315` | ~~EEDS: patch Event::Camp~~ | **revert** par `a75acea1` |
| `a75acea1` | Revert "EEDS: patch Event::Camp" | Restaure comportement PBS |

### Locales clefs renommées (FR EEDS)

- `pbs_number` → « Matricule EEDS » (au lieu de « N° personnel MSdS »)
- `kantonalverband` / `kv` → « Région EEDS »
- `pronouns` → « Pronoms » (était en allemand)
- `black_list/pbs_number` → « Matricule EEDS »
- Phone labels prédéfinis : Domicile, GSM, Travail, Père, Mère, Fax, Autre
- Social labels : WhatsApp, Facebook, Instagram, Skype, Site web, Autre
- Additional address : Travail, Parents, Internat

### Comportements modifiés (fork PBS)

- `language` par défaut = `fr`
- Visibilité par défaut des fiches membres assouplie
- Cascade soft-delete pour éviter des références orphelines

## Core `hitobito` upstream

Pas de fork — utilisé tel quel via `app/hitobito/`. Toutes les adaptations
EEDS passent par le wagon ou par le fork PBS.

## Pièges identifiés

### 1. Settings prédéfinis (Config gem)

Le gem `Config` **concatène** les arrays par défaut au lieu de les
remplacer. Sans override explicite, les labels prédéfinis (phones, socials,
etc.) accumulent ceux de hitobito + youth + pbs + eeds.

Solution dans `lib/hitobito_eeds/wagon.rb` :

```ruby
initializer "hitobito_eeds.override_predefined_labels",
            after: :load_config_initializers do |_app|
  Settings.phone_number.predefined_labels      = %w[Domicile GSM Travail Père Mère Fax Autre]
  Settings.social_account.predefined_labels    = ["WhatsApp", "Facebook", "Instagram", "Skype", "Site web", "Autre"]
  Settings.additional_address.predefined_labels = %w[Travail Parents Internat]
end
```

### 2. `administrative_region` partagé entre Person et Group (via les vues)

Le partial `contactable/_address_fields.html.haml` est rendu pour `Person`
ET pour `Group`. `administrative_region` n'existe que sur `Person`, donc
le champ est conditionné par `f.object.respond_to?(:administrative_region)`
pour éviter une `NoMethodError` sur l'édition de groupe.

### 3. Migrations de wagon invisibles à `db:migrate`

`rake db:migrate` ne voit que les migrations du host hitobito. Utiliser
`rake wagon:migrate WAGON=eeds` (cf. [Workflow](workflow.md)).

### 4. Données seed orphelines après re-seed

Les seeds PBS d'origine créent des `Event::Course`, `Event::Camp` et
participations rattachés à des groupes Suisses. Si on re-seed avec la
hiérarchie EEDS, ces événements pointent vers des `group_id` qui n'existent
plus → `NoMethodError` sur `/list_courses` et `/events/:id/participations`.

→ Toujours nettoyer après un changement de hiérarchie de groupes :

```ruby
# rails runner
Event.left_joins(:groups).where(groups: {id: nil}).find_each(&:destroy)
Event::Participation.where.missing(:person).find_each(&:destroy)
```

### 5. Event::Camp reverté

Le patch `ec028315` qui tentait d'adapter Event::Camp au contexte
sénégalais (retirer coach/abteilungsleitung/J+S) a été reverté car les
vues PBS d'origine en dépendaient (`undefined method 'coach' for Event::Camp`).
On garde le comportement PBS standard pour Event::Camp pour l'instant ;
adaptation à reprendre via overrides de vues si vraiment nécessaire.
