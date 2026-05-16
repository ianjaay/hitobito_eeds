# Architecture

EEDS s'adosse à 3 dépôts Git imbriqués. Cette stratégie permet de séparer
clairement ce qui est upstream, ce qui est un fork rebaseable, et ce qui est
purement EEDS.

```
GalleApp/                         ← dépôt host (docker, configuration, Wagonfile)
├── app/                          ← code Rails monté dans le container Docker
│   ├── hitobito/                 ← core upstream (read-only, sous-module logique)
│   ├── hitobito_pbs/             ← fork EEDS du wagon PBS (branche eeds-customizations)
│   ├── hitobito_youth/           ← wagon youth upstream (dépendance de pbs)
│   ├── hitobito_eeds/            ← wagon EEDS-spécifique (CE dépôt)
│   └── …
├── docker/                       ← images Rails / postgres / mailcatcher / webpack
└── docker-compose.yml            ← Rails sur :3010, postgres sur :5435
```

## Les 3 dépôts

### 1. `GalleApp` (host)

- Repo : `ianjaay/GalleApp` (branche `master`)
- Contient : `docker-compose.yml`, scripts seed/reset, `Wagonfile`,
  logo EEDS source.
- **Ne contient pas** de code Rails ; tout est monté depuis `app/`.

### 2. `hitobito_pbs` (fork)

- Repo : `ianjaay/hitobito_pbs`
- Branche de travail : `eeds-customizations`
- Stratégie : **modifier en place** les libellés et fonctionnalités PBS
  pour les adapter au Sénégal (renommage en FR, désactivation J+S, etc.).
- Pourquoi un fork plutôt qu'un wagon override ? Beaucoup de PBS est
  Suisse-spécifique au point que monkey-patcher ferait plus de bruit
  que de modifier directement. Le fork reste rebaseable sur `upstream/master`.
- Voir [Divergences](divergences.md) pour la liste des commits.

### 3. `hitobito_eeds` (wagon)

- Repo : interne à `app/hitobito_eeds/` (ce dépôt)
- Stratégie : **toutes les nouveautés EEDS** (nouveaux champs Person,
  Group::Subgroup, branches de progression, locales FR EEDS, etc.) vivent
  ici. Pas de dette technique reportée dans le fork.
- Dépend de `hitobito_pbs` (gemspec).

## Ordre de chargement des wagons

```
core (hitobito) → youth → pbs → eeds
```

Conséquence pratique : le wagon `eeds` peut surcharger n'importe quoi de
`pbs`, `youth` ou du core via `config.to_prepare` et via les vues
(les partials du wagon le plus tardif gagnent).

## Points d'extension du wagon `hitobito_eeds`

Fichier : `lib/hitobito_eeds/wagon.rb`

| Type d'extension | Mécanisme |
|---|---|
| Étendre le modèle Person | `Person.include Eeds::Person` dans `to_prepare` |
| Permitted attrs | `PeopleController.permitted_attrs -=/+= [...]` dans `to_prepare` |
| Nouveau type de groupe | `app/models/group/subgroup.rb` (auto-loadé), wiring `unit.children(Group::Subgroup)` |
| Surcharge de Settings (labels phone/social/address) | initializer `override_predefined_labels` après `:load_config_initializers` (sinon Config gem **concatène** au lieu de remplacer) |
| Locales FR EEDS | `config/locales/*.eeds.fr.yml` (chargés automatiquement) |
| Migrations | `db/migrate/*.rb` — **rake db:migrate ne les voit PAS**, utiliser `rake wagon:migrate WAGON=eeds` (cf. [Workflow](workflow.md)) |
| Seeds idempotents | `db/seeds/*.rb` — `rake wagon:seed WAGON=eeds` |
| Vues (override) | `app/views/{controller}/{partial}.html.haml` |
