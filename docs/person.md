# Modèle Person — adaptations EEDS

Adaptations apportées par le wagon `hitobito_eeds` au modèle `Person`
hitobito (+ extensions youth + pbs).

## Nouveaux attributs

| Colonne SQL | Type | Migration | Section UI |
|---|---|---|---|
| `birthplace` | `string` | `20260510175322_add_eeds_identity_to_people.rb` | Informations personnelles |
| `nationality` | `string` (défaut `"Sénégalaise"`) | `20260510175322_add_eeds_identity_to_people.rb` | Informations personnelles |
| `administrative_region` | `string` | `20260510175719_add_administrative_region_to_people.rb` | Coordonnées (adresse) |
| `emergency_contact_name` | `string` | `20260510175930_add_emergency_contact_to_people.rb` | Coordonnées (bloc Contact d'urgence) |
| `emergency_contact_phone` | `string` | `20260510175930_add_emergency_contact_to_people.rb` | idem |
| `emergency_contact_relation` | `string` | `20260510175930_add_emergency_contact_to_people.rb` | idem |
| `has_family_in_scouting` | `boolean` | `20260510184700_add_has_family_in_scouting_to_people.rb` | Informations dans le scoutisme |

## Validations

```ruby
# app/models/eeds/person.rb
validates :administrative_region,
  inclusion: {in: SENEGAL_REGIONS, allow_blank: true}
```

`SENEGAL_REGIONS` = liste figée des 14 régions administratives du Sénégal
(ordre alphabétique, voir constante dans `app/models/eeds/person.rb`).
Utilisée par le `select` dans le formulaire d'adresse.

## Attributs étendus

Pour chacun des nouveaux champs, le wagon EEDS doit déclarer son intention
dans plusieurs collections clés :

| Collection | Où | Pourquoi |
|---|---|---|
| `Person::PUBLIC_ATTRS` | `app/models/eeds/person.rb` | Sérialisation API/JSON |
| `Person::ADDRESS_ATTRS` | idem (`administrative_region` uniquement) | Bloc adresse du formulaire |
| `Person::SEARCHABLE_ATTRS` | idem | Quicksearch en haut à droite |
| `Person::FILTER_ATTRS` | idem | Filtres avancés de la liste des personnes |
| `PeopleController.permitted_attrs` | `lib/hitobito_eeds/wagon.rb` `to_prepare` | Strong params (sinon ignoré au POST) |

⚠️ Si tu ajoutes un nouveau champ EEDS, **n'oublie pas les 5 collections**
ci-dessus, sinon : le champ est silencieusement ignoré au formulaire (pas
permitted), invisible en API (pas dans PUBLIC), introuvable en recherche.

## Désactivations Suisse-spécifiques

```ruby
# lib/hitobito_eeds/wagon.rb
PeopleController.permitted_attrs -= [:j_s_number]  # N° Jeunesse+Sport (programme suisse)

# app/models/eeds/person.rb
skip_callback :save, :after, :send_black_list_mail  # Blacklist SMS suisse

def black_listed?
  false  # neutralise les appels directs depuis Pbs::Role / Pbs::Event::Participation
end
```

## Helpers EEDS

```ruby
person.current_branch  # → Qualification (Jiwu / Lawtan / Toor-Toor / Mennef) la plus récente, ou nil
```

Voir [Branches](branches.md) pour la modélisation des 4 niveaux de
progression.

## Vues overridées

Toutes dans `app/views/people/` et `app/views/contactable/` :

| Partial | Rôle |
|---|---|
| `people/_fields_eeds.html.haml` | Sections « Informations dans le scoutisme » (matricule, has_family_in_scouting, entry/leaving_date) + « Contact d'urgence » |
| `people/_details_eeds.html.haml` | Fiche : birthplace, nationality, current_branch, contacts d'urgence |
| `people/_fields_pbs.html.haml` | **Vidé** (drops grade_of_school, pronouns, title, salutation) |
| `people/_fields_youth.html.haml` | **Vidé** (drops j_s_number, nationality_j_s) |
| `people/_details_pbs.html.haml` | Réduit à pbs_number + language |
| `people/_details_youth.html.haml` | **Vidé** |
| `contactable/_address_fields.html.haml` | 4 champs SN simplifiés + `administrative_region` (conditionné par `respond_to?` pour ne pas casser `Group#edit`) |
| `contactable/_fields.html.haml` | Email/phone/extras/socials groupés dans le bloc adresse, légende « Coordonnées » |

## Locales FR

| Fichier | Contenu |
|---|---|
| `config/locales/models.eeds.fr.yml` | Labels FR : street, town, administrative_region, birthplace, nationality, has_family_in_scouting, noms de sections du formulaire |
| `config/locales/contactable.eeds.fr.yml` | `section_contact: "Coordonnées"` |
| `config/locales/groups.eeds.fr.yml` | Labels FR pour Group::Subgroup et ses rôles |
