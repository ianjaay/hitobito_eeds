# Hitobito EEDS

Wagon Hitobito pour les **Éclaireuses et Éclaireurs du Sénégal** (EEDS).

Ce wagon définit la hiérarchie organisationnelle, les types de groupes et les
rôles propres aux EEDS, en s'appuyant sur le cœur Hitobito.

## Hiérarchie EEDS

```
Root (système)
└── National                        (layer)
    └── Région                      (layer, 14 régions du Sénégal)
        └── District                (layer)
            └── Groupe Local        (layer)
                ├── Mbootaay        (Jiwu wi, 5–11 ans)
                ├── Kayon           (Lawtan wi, 12–15 ans)
                ├── Ñawka           (Toor-Toor wi, 16–18 ans)
                └── Gàlle           (Meññeef mi, 18+ ans)
```

## Développement

Voir le `README.md` du dépôt parent (`hitobito/`) pour la mise en place de
l'environnement Docker.

```bash
# À la racine de hitobito/ :
hit up
hit test
```

## Licence

AGPL-3.0 — voir le fichier `COPYING`.
