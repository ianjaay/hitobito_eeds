# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Group::District do
  subject(:type) { described_class }

  it "is a layer" do
    expect(type.layer).to be true
  end

  it "accepts Groupe local as direct child" do
    expect(type.possible_children).to eq([Group::GroupeLocal])
  end

  it "declares the expected role types" do
    expect(type.role_types).to match_array([
      Group::District::CommissaireDistrict,
      Group::District::CommissaireDistrictAdjoint,
      Group::District::RespBrancheJiwu,
      Group::District::RespBrancheLawtan,
      Group::District::RespBrancheToorToor,
      Group::District::RespBrancheMenneef,
      Group::District::SecretaireDistrict,
      Group::District::TresorierDistrict
    ])
  end

  it "enforces 2FA on the Commissaire de district role" do
    expect(Group::District::CommissaireDistrict.two_factor_authentication_enforced).to be true
  end
end
