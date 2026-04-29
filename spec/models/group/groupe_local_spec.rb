# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Group::GroupeLocal do
  subject(:type) { described_class }

  it "is a layer" do
    expect(type.layer).to be true
  end

  it "accepts the four branche unit groups as children" do
    expect(type.possible_children).to match_array([
      Group::Mbootaay,
      Group::Kayon,
      Group::Nawka,
      Group::Galle
    ])
  end

  it "declares the expected role types" do
    expect(type.role_types).to match_array([
      Group::GroupeLocal::ChefGroupe,
      Group::GroupeLocal::MembreMaitrise,
      Group::GroupeLocal::RespUniteMbootaay,
      Group::GroupeLocal::RespUniteKayon,
      Group::GroupeLocal::RespUniteNawka,
      Group::GroupeLocal::RespUniteGalle,
      Group::GroupeLocal::SecretaireLocal,
      Group::GroupeLocal::TresorierLocal
    ])
  end

  it "enforces 2FA on the Chef de groupe role" do
    expect(Group::GroupeLocal::ChefGroupe.two_factor_authentication_enforced).to be true
  end

  it "grants finance permission to the Trésorier·ière local·e" do
    expect(Group::GroupeLocal::TresorierLocal.permissions).to include(:finance)
  end
end
