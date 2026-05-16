# Branches de progression EEDS

Au sein de chaque unité, un jeune passe successivement par 4 niveaux de
progression. Ces niveaux sont modélisés comme des `QualificationKind`
hitobito plutôt que comme un nouveau modèle dédié.

## Les 4 branches

| ID | Clé interne | Label FR | Couleur |
|---|---|---|---|
| 1001 | `jiwu` | Jiwu wi | Jaune |
| 1002 | `lawtan` | Lawtan wi | Vert |
| 1003 | `toor_toor` | Toor-Toor wi | Blanc |
| 1004 | `mennef` | Mennef mi | Rouge |

IDs **réservés EEDS dans la plage 1001–1099** (cf. `EEDS_BRANCH_IDS` dans
`app/models/eeds/person.rb` et `db/seeds/branches.rb`). Les `QualificationKind`
upstream et PBS utilisent des IDs séquentiels bas, donc cette plage est
sûre pour éviter les conflits.

## Pourquoi `QualificationKind` plutôt qu'un modèle dédié ?

Avantages obtenus gratuitement :

- Attribution datée (`start_at`, `finish_at`, `qualified_at`)
- Historique de progression complet par personne
- Inclus dans les exports CSV via `PeopleFull`
- Recherche et filtres natifs
- API JSON
- Vue dédiée par personne (`/people/:id/qualifications`)

## Seeds idempotents

Fichier : `db/seeds/branches.rb`

```ruby
quali_kinds = QualificationKind.seed(:id,
  *EEDS_BRANCHES.map { |b| {id: b[:id], validity: nil, reactivateable: nil} }
)

QualificationKind::Translation.seed(:qualification_kind_id, :locale,
  *EEDS_BRANCHES.flat_map { |b| [
    {qualification_kind_id: b[:id], locale: "fr",
     label: "#{b[:label_fr]} (#{b[:color]})", description: "..."},
    {qualification_kind_id: b[:id], locale: "de", label: b[:label_fr]},
    {qualification_kind_id: b[:id], locale: "en", label: b[:label_fr]},
    {qualification_kind_id: b[:id], locale: "it", label: b[:label_fr]}
  ] }
)
```

- `seed(:id, …)` est idempotent : relance sans risque.
- `validity: nil` = pas d'expiration (un brevet de branche ne périme pas).
- `reactivateable: nil` = champ optionnel ; les branches ne se réactivent
  pas, on en obtient simplement une nouvelle.

Exécution :

```bash
docker compose exec rails bash -lc '
  cd /usr/src/app/hitobito &&
  bundle exec rake wagon:seed WAGON=eeds
'
```

## Helper Person

```ruby
person.current_branch
# → renvoie la Qualification de branche EEDS la plus récente
#   (max start_at puis max id), ou nil si aucune.
```

Implémenté dans `app/models/eeds/person.rb`. Utilisé dans
`app/views/people/_details_eeds.html.haml` pour afficher la branche en cours.

## Workflow d'attribution

Pour attribuer une branche à un jeune :

1. Aller sur sa fiche : `/people/:id`
2. Onglet **Qualifications**
3. **Ajouter** → sélectionner « Jiwu wi (Jaune) » (etc.)
4. Renseigner `start_at` (date de passage)

Le passage à la branche suivante = créer une nouvelle qualification avec
le nouveau `QualificationKind` (la précédente reste dans l'historique).
