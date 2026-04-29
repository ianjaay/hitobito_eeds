# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Niveau National (équivalent PBS Bund). Racine fonctionnelle de l'arbre EEDS.
#
# Pilotage politique et exécutif de l'association :
#   - Commissaire National  : président·e, autorité fonctionnelle suprême
#   - Adjoints par branche  : 4 (Jiwu, Lawtan, Toor-Toor, Meññeef)
#   - Adjoints thématiques  : 4 (formation, communication, programme, international)
#   - Bureau exécutif       : membres élus / nommés au bureau
#   - Trésorier·ière + Secrétaire général·e
class Group::National < Group
  self.layer = true
  self.event_types = [Event, Event::Course, Event::Camp]

  children Group::RegionEeds,
    Group::DistrictAutonome,
    Group::GroupeLocalAutonome,
    Group::CommissionNationale,
    Group::Anciens,
    Group::ScoutsHandicap

  ### Rôles ###

  class CommissaireNational < ::Role
    self.permissions = [:layer_and_below_full, :admin, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  # Adjoints par branche pédagogique
  class CommissaireAdjointJiwu < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class CommissaireAdjointLawtan < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class CommissaireAdjointToorToor < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class CommissaireAdjointMenneef < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  # Adjoints thématiques
  class CommissaireFormation < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class CommissaireCommunication < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class CommissaireProgramme < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class CommissaireInternational < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  # Bureau exécutif
  class MembreBureauExecutif < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  # Fonctions support
  class SecretaireGeneral < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  class TresorierNational < ::Role
    self.permissions = [:layer_and_below_full, :finance, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  roles CommissaireNational,
    CommissaireAdjointJiwu,
    CommissaireAdjointLawtan,
    CommissaireAdjointToorToor,
    CommissaireAdjointMenneef,
    CommissaireFormation,
    CommissaireCommunication,
    CommissaireProgramme,
    CommissaireInternational,
    MembreBureauExecutif,
    SecretaireGeneral,
    TresorierNational
end
