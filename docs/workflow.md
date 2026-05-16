# Workflow de développement

## Stack Docker

| Service | Image | Port hôte | Rôle |
|---|---|---|---|
| `rails` | `ghcr.io/hitobito/development/rails` | `127.0.0.1:3010` | Serveur Rails (Puma) |
| `webpack` | idem | `127.0.0.1:3035` | Webpack dev server |
| `worker` | idem | — | Delayed::Job |
| `postgres` | `postgres:17` | `127.0.0.1:5435` | DB de dev |
| `cache` | `memcached:1.6-alpine` | interne | Cache Rails |
| `mailcatcher` | `ghcr.io/hitobito/development/mailcatcher` | `127.0.0.1:1025` (SMTP), `127.0.0.1:1080` (UI) | Capture des emails |

Le port Rails a été déplacé à **3010** (au lieu du 3000 par défaut) pour ne
pas entrer en collision avec d'autres apps dev locales. Voir
`docker-compose.yml` ligne `ports: 127.0.0.1:3010:3000`.

## Commandes courantes

Toutes ces commandes s'exécutent depuis `GalleApp/`.

```bash
# Démarrer toute la stack
docker compose up -d

# Voir l'état
docker compose ps

# Logs Rails
docker compose logs -f rails

# Shell dans le container Rails
docker compose exec rails bash

# Rails console
docker compose exec rails bash -lc 'cd /usr/src/app/hitobito && bin/rails c'

# Rails runner one-shot
docker compose exec -T rails bash -lc 'cd /usr/src/app/hitobito && bin/rails runner "puts Person.count"'

# Redémarrer Rails (après changement de code dans lib/, app/models/concerns/, etc.)
docker compose restart rails
```

## Migrations de wagon

⚠️ **Piège classique** : `rake db:migrate` ne voit que les migrations du
**host hitobito**, pas celles des wagons. Pour migrer un wagon :

```bash
docker compose exec rails bash -lc '
  cd /usr/src/app/hitobito &&
  bundle exec rake wagon:migrate WAGON=eeds
'

# Lister l'état de toutes les migrations (host + wagons)
docker compose exec rails bash -lc '
  cd /usr/src/app/hitobito &&
  bundle exec rake db:migrate:status_all
'
```

Remplacer `WAGON=eeds` par `WAGON=pbs` pour migrer le wagon PBS.

## Seeds de wagon

Idempotents (`QualificationKind.seed(:id, …)`), donc relançables à volonté :

```bash
docker compose exec rails bash -lc '
  cd /usr/src/app/hitobito &&
  bundle exec rake wagon:seed WAGON=eeds
'
```

Charge `app/hitobito_eeds/db/seeds/*.rb` (notamment `branches.rb` pour les
4 QualificationKind 1001–1004, cf. [Branches](branches.md)).

## Reset complet de la DB

Scripts à la racine de `GalleApp` (à vérifier avant de lancer en prod !) :
voir `bin/setup`, `bin/db-reset-and-seed` ou équivalent (cf.
`docker-compose.yml` `SKIP_SEEDS`).

Pour ne PAS rejouer les seeds au prochain démarrage : décommenter
`SKIP_SEEDS: 1` dans `docker-compose.yml`.

## Tests de fumée (smoke checks)

Vérification rapide que rien n'a explosé après un changement :

```bash
# Endpoints clés
for p in / /people/new /list_courses /groups; do
  curl -sS -o /dev/null -w "$p=%{http_code}\n" http://localhost:3010$p
done
# Tous doivent répondre 302 (redirect login) — un 500 = problème.

# Sanity check ORM (colonnes, attributs, features)
docker compose exec -T rails bash -lc 'cd /usr/src/app/hitobito && bin/rails runner "
  puts \"Person columns EEDS: #{(%w[birthplace nationality administrative_region] - Person.column_names).empty?}\"
  puts \"Subgroup loaded: #{defined?(Group::Subgroup)}\"
  puts \"Branches: #{QualificationKind.where(id: 1001..1004).count}\"
"'
```

## Workflow Git multi-dépôts

```bash
# Travail dans le wagon EEDS
cd app/hitobito_eeds && git add … && git commit -m "..."
# (pas de remote configuré pour ce wagon, repo interne)

# Travail dans le fork PBS
cd app/hitobito_pbs
git checkout eeds-customizations
git add … && git commit -m "EEDS: ..."
git push origin eeds-customizations  # ianjaay/hitobito_pbs

# Travail host
cd GalleApp
git add … && git commit -m "..."
git push origin master  # ianjaay/GalleApp
```

## Convention de commit

Préfixer les commits qui touchent au contexte EEDS par `EEDS:` (utilisé
historiquement sur les 3 dépôts pour les distinguer des commits upstream).
