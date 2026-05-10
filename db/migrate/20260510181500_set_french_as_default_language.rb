# frozen_string_literal: true

# EEDS — La langue par défaut historique de hitobito est "de" (allemand).
# Comme E-Gàlle n'expose que le français dans Settings.application.languages,
# tout nouveau Person créé hérite "de" via le défaut de schéma puis échoue
# à la validation `i18n_enum :language` ("n'est pas inclus(e) dans la liste").
#
# Cette migration :
#   1. Aligne le défaut de la colonne sur "fr".
#   2. Backfille les données existantes (sécurité, normalement déjà fait).
class SetFrenchAsDefaultLanguage < ActiveRecord::Migration[7.1]
  def up
    change_column_default :people, :language, from: "de", to: "fr"
    execute <<~SQL.squish
      UPDATE people SET language = 'fr'
      WHERE language IS NULL OR language NOT IN ('fr')
    SQL
  end

  def down
    change_column_default :people, :language, from: "fr", to: "de"
  end
end
