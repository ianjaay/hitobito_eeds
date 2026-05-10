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

  included do
    # Attributs d'identité EEDS exposés publiquement.
    Person::PUBLIC_ATTRS << :birthplace << :nationality << :administrative_region
    Person::ADDRESS_ATTRS << "administrative_region"
    Person::SEARCHABLE_ATTRS << :nationality

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
end
