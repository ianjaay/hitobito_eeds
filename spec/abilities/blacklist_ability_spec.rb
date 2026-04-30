# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe BlacklistAbility do
  let(:national) { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }

  it "Commissaire National (admin) can manage blacklist" do
    user = Fabricate(Group::National::CommissaireNational.name.to_sym, group: national).person
    a = Ability.new(user)
    expect(a).to be_able_to(:create, Blacklist.new)
    expect(a).to be_able_to(:destroy, Blacklist.new)
  end

  it "ChefGroupe cannot access blacklist" do
    gl = Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL", parent: national)
    user = Fabricate(Group::GroupeLocalAutonome::ChefGroupe.name.to_sym, group: gl).person
    a = Ability.new(user)
    expect(a).not_to be_able_to(:create, Blacklist.new)
    expect(a).not_to be_able_to(:index, Blacklist)
  end
end
