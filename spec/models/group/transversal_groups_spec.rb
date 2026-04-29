# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

# Specs des structures transversales rattachées au National :
# Commissions Nationales (formation, communication, etc.), Anciens éclaireurs,
# Scouts Handicap (SMT).

describe Group::CommissionNationale do
  subject(:type) { described_class }

  it "is a possible child of Group::National" do
    expect(Group::National.possible_children).to include(type)
  end

  it "declares Coordinateur, Membre, Encadreur, Conseiller as roles" do
    role_names = type.role_types.map { |r| r.name.demodulize.to_sym }
    expect(role_names).to match_array([:CoordinateurCommission, :MembreCommission, :Encadreur, :Conseiller])
  end

  it "uses MembreCommission as the standard role" do
    expect(type.standard_role).to eq(type::MembreCommission)
  end
end

describe Group::Anciens do
  subject(:type) { described_class }

  it "is a layer and a possible child of Group::National" do
    expect(type.layer).to be true
    expect(Group::National.possible_children).to include(type)
  end

  it "declares Président, MembreBureau, Membre" do
    role_names = type.role_types.map { |r| r.name.demodulize.to_sym }
    expect(role_names).to match_array([:President, :MembreBureau, :Membre])
  end

  it "uses Membre as the standard role and hides it from above" do
    expect(type.standard_role).to eq(type::Membre)
    expect(type::Membre.visible_from_above).to be false
  end
end

describe Group::ScoutsHandicap do
  subject(:type) { described_class }

  it "is a layer and a possible child of Group::National" do
    expect(type.layer).to be true
    expect(Group::National.possible_children).to include(type)
  end

  it "declares Coordinateur, Encadreur, Conseiller, Membre" do
    role_names = type.role_types.map { |r| r.name.demodulize.to_sym }
    expect(role_names).to match_array([:Coordinateur, :Encadreur, :Conseiller, :Membre])
  end

  it "enforces 2FA on the Coordinateur SMT" do
    expect(type::Coordinateur.two_factor_authentication_enforced).to be true
  end
end
