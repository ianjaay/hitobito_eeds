# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe CrisisAbility do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL Abi", parent: national) }
  let(:other_gl)     { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL Other", parent: national) }
  let(:crisis)       { Crisis.new(group: groupe_local, kind: "accident", severity: "high") }

  def ability_for(role_class, group:)
    user = Fabricate(role_class.name.to_sym, group: group).person
    Ability.new(user)
  end

  it "Chef Groupe can create on his groupe local" do
    expect(ability_for(Group::GroupeLocalAutonome::ChefGroupe, group: groupe_local))
      .to be_able_to(:create, crisis)
  end

  it "Chef Groupe of another GL cannot create on this GL" do
    expect(ability_for(Group::GroupeLocalAutonome::ChefGroupe, group: other_gl))
      .not_to be_able_to(:create, crisis)
  end

  it "Chef Groupe can acknowledge crises in his groupe local (layer_and_below_full)" do
    expect(ability_for(Group::GroupeLocalAutonome::ChefGroupe, group: groupe_local))
      .to be_able_to(:acknowledge, crisis)
  end

  it "Chef Groupe of another GL cannot acknowledge crises in this one" do
    expect(ability_for(Group::GroupeLocalAutonome::ChefGroupe, group: other_gl))
      .not_to be_able_to(:acknowledge, crisis)
  end

  it "Commissaire National can acknowledge and complete any crisis" do
    user = Fabricate(Group::National::CommissaireNational.name.to_sym, group: national).person
    a = Ability.new(user)
    expect(a).to be_able_to(:acknowledge, crisis)
    expect(a).to be_able_to(:complete, crisis)
  end
end
