# frozen_string_literal: true

#  Copyright (c) 2025, Éclaireuses et Éclaireurs du Sénégal.
#  Adaptation EEDS du modèle Person.

module Eeds::Person
  extend ActiveSupport::Concern

  # Liste des 14 régions administratives du Sénégal (ordre alphabétique).
  # Utilisée pour le select du champ `administrative_region` dans le form personne.
  SENEGAL_REGIONS = [
    "Dakar",
    "Diourbel",
    "Fatick",
    "Kaffrine",
    "Kaolack",
    "Kédougou",
    "Kolda",
    "Louga",
    "Matam",
    "Saint-Louis",
    "Sédhiou",
    "Tambacounda",
    "Thiès",
    "Ziguinchor"
  ].freeze

  # IDs des QualificationKind représentant les 4 branches de progression EEDS
  # (cf. db/seeds/branches.rb). Réservés dans la plage 1001-1099.
  EEDS_BRANCH_IDS = [1001, 1002, 1003, 1004].freeze

  included do
    # Attributs d'identité EEDS exposés publiquement.
    Person::PUBLIC_ATTRS << :birthplace << :nationality << :administrative_region <<
      :emergency_contact_name << :emergency_contact_phone << :emergency_contact_relation <<
      :has_family_in_scouting
    Person::ADDRESS_ATTRS << "administrative_region"
    Person::SEARCHABLE_ATTRS << :nationality << :birthplace <<
      :emergency_contact_name << :emergency_contact_phone

    # Filtres avancés de la liste des personnes (search_strategy + Quicksearch).
    Person::FILTER_ATTRS.push(
      :birthplace,
      :nationality,
      :administrative_region,
      :emergency_contact_name,
      :emergency_contact_phone,
      :emergency_contact_relation
    )

    validates :administrative_region,
      inclusion: {in: SENEGAL_REGIONS, allow_blank: true}

    # Désactiver l'envoi automatique de mails liés à la BlackList suisse.
    # Le système de blacklist hitobito_pbs est conçu pour la Suisse (numéros de tél
    # interdits, etc.) ; non pertinent dans le contexte EEDS.
    skip_callback :save, :after, :send_black_list_mail
  end

  # Override : neutraliser également l'appel direct depuis Pbs::Role / Pbs::Event::Participation
  # qui appellent `BlackListMailer.hit(...)` directement (pas via callback).
  # Voir `app/models/pbs/role.rb:56` et `app/models/pbs/event/participation.rb:38`.
  def black_listed?
    false
  end

  # Renvoie la dernière qualification de progression EEDS (Jiwu / Lawtan /
  # Toor-Toor / Mennef) obtenue par la personne, ou nil.
  def current_branch
    qualifications
      .where(qualification_kind_id: EEDS_BRANCH_IDS)
      .order(start_at: :desc, id: :desc)
      .first
  end
end
