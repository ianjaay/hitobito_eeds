# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Group::GroupeLocalAutonome do
  subject(:type) { described_class }

  it "is a layer" do
    expect(type.layer).to be true
  end

  it "is a possible child of Group::National" do
    expect(Group::National.possible_children).to include(type)
  end

  it "accepts the four EEDS branches as direct children" do
    expect(type.possible_children).to match_array([
      Group::Mbootaay,
      Group::Kayon,
      Group::Nawka,
      Group::Galle
    ])
  end

  it "declares the expected role types" do
    expect(type.role_types).to match_array([
      Group::GroupeLocalAutonome::ChefGroupe,
      Group::GroupeLocalAutonome::ChefGroupeAdjoint,
      Group::GroupeLocalAutonome::SecretaireLocal,
      Group::GroupeLocalAutonome::TresorierLocal,
      Group::GroupeLocalAutonome::RespMateriel,
      Group::GroupeLocalAutonome::RespParents
    ])
  end

  it "enforces 2FA on the Chef·fe de groupe" do
    expect(type::ChefGroupe.two_factor_authentication_enforced).to be true
  end
end
