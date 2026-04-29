# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Extension de Person avec les champs propres aux EEDS :
#
# Champs scoutes :
#   - matricule_scout : identifiant unique attribué par le National
#   - branche         : énum {mbootaay, kayon, nawka, galle}
#   - unite           : nom de la sizaine / patrouille / équipe
#   - assurance_expiration : date d'expiration de la couverture assurance
#   - progression_badges   : texte libre (badges, brevets obtenus)
#
# Coordonnées du parent (pour les mineurs) :
#   - parent_contact_name, parent_contact_phone, parent_contact_email
#
# Profil personnel :
#   - profession  : profession civile
#   - competences : texte libre (cuisine, secourisme, langues parlées, etc.)
module Eeds::Person
  extend ActiveSupport::Concern

  BRANCHES = %w[mbootaay kayon nawka galle].freeze

  # Format E.164-ish lâche : optionnel +, 8 à 15 chiffres avec espaces/tirets
  # tolérés. Les imports CSV peuvent contenir des notations diverses.
  PHONE_REGEX = /\A\+?[\d\s\-().]{8,20}\z/

  EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  included do
    Person::PUBLIC_ATTRS.concat(%i[
      matricule_scout
      branche
      unite
      assurance_expiration
      progression_badges
      parent_contact_name
      parent_contact_phone
      parent_contact_email
      profession
      competences
    ])

    Person::SEARCHABLE_ATTRS << :matricule_scout

    i18n_enum :branche, BRANCHES, scopes: true, queries: false

    validates :matricule_scout,
      uniqueness: {case_sensitive: false, allow_blank: true},
      length: {maximum: 50}

    validates :parent_contact_phone,
      format: {with: PHONE_REGEX, allow_blank: true}

    validates :parent_contact_email,
      format: {with: EMAIL_REGEX, allow_blank: true}
  end

  # Indique si la personne a au moins un canal de contact parental renseigné.
  def parent_contact?
    parent_contact_name.present? ||
      parent_contact_phone.present? ||
      parent_contact_email.present?
  end

  # Représentation textuelle compacte du contact parent.
  def parent_contact_summary
    [parent_contact_name, parent_contact_phone, parent_contact_email]
      .compact_blank
      .join(" • ")
  end
end
