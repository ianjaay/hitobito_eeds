# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Group::National do
  subject(:type) { described_class }

  it "is a layer" do
    expect(type.layer).to be true
  end

  it "is registered as a root_type of the EEDS hierarchy" do
    expect(Group.root_types).to include(type)
  end

  it "accepts Région, District Autonome and Groupe Local Autonome as direct children" do
    expect(type.possible_children).to match_array([
      Group::RegionEeds,
      Group::DistrictAutonome,
      Group::GroupeLocalAutonome
    ])
  end

  it "declares the expected role types" do
    expect(type.role_types).to match_array([
      Group::National::President,
      Group::National::CommissaireGeneral,
      Group::National::CommissaireInternational,
      Group::National::TresorierNational,
      Group::National::SecretaireGeneral,
      Group::National::RespCommunication,
      Group::National::RespDigital,
      Group::National::RespFormation,
      Group::National::RespProgrammeJeunes
    ])
  end

  it "enforces 2FA on senior leadership roles" do
    [
      Group::National::President,
      Group::National::CommissaireGeneral,
      Group::National::CommissaireInternational,
      Group::National::TresorierNational,
      Group::National::SecretaireGeneral
    ].each do |role|
      expect(role.two_factor_authentication_enforced).to be(true), "#{role} should enforce 2FA"
    end
  end

  it "grants admin permission to the Président and Commissaire Général" do
    [Group::National::President, Group::National::CommissaireGeneral].each do |role|
      expect(role.permissions).to include(:admin, :layer_and_below_full)
    end
  end
end
