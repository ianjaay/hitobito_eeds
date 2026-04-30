# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe MemberCountAbility do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS Test") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL MC", parent: national) }
  let(:other_gl)     { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL Other", parent: national) }

  let(:mc) { MemberCount.new(group: groupe_local, year: 2026) }

  def ability_for(role_class, group:)
    user = Fabricate(role_class.name.to_sym, group: group).person
    Ability.new(user)
  end

  it "ChefGroupe (layer_and_below_full) can update member counts of his groupe local" do
    expect(ability_for(Group::GroupeLocalAutonome::ChefGroupe, group: groupe_local))
      .to be_able_to(:update, mc)
  end

  it "ChefGroupe of another groupe local cannot update member counts of this one" do
    expect(ability_for(Group::GroupeLocalAutonome::ChefGroupe, group: other_gl))
      .not_to be_able_to(:update, mc)
  end

  it "Commissaire National can read member counts of any groupe local" do
    user = Fabricate(Group::National::CommissaireNational.name.to_sym, group: national).person
    expect(Ability.new(user)).to be_able_to(:show, mc)
  end
end
