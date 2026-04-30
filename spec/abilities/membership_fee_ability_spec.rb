# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe MembershipFeeAbility do
  let(:national)    { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS Test") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL Abi", parent: national) }
  let(:other_gl)    { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL Other", parent: national) }
  let(:person)      { Fabricate(:person) }

  let(:fee) do
    MembershipFee.new(person: person, group: groupe_local, year: 2026,
      branche: "jiwu", amount_cents: 5_000_00, currency: "XOF", status: "pending")
  end

  def ability_for(role_factory, group:)
    user = Fabricate(role_factory.name.to_sym, group: group).person
    Ability.new(user)
  end

  it "TresorierLocal can manage fees of his groupe local" do
    expect(ability_for(Group::GroupeLocalAutonome::TresorierLocal, group: groupe_local))
      .to be_able_to(:update, fee)
  end

  it "TresorierLocal of another groupe local cannot manage fees of this one" do
    expect(ability_for(Group::GroupeLocalAutonome::TresorierLocal, group: other_gl))
      .not_to be_able_to(:update, fee)
  end

  it "TresorierNational can manage fees of any groupe local" do
    expect(ability_for(Group::National::TresorierNational, group: national))
      .to be_able_to(:update, fee)
  end

  it "Plain member cannot manage fees" do
    member = Fabricate(Group::GroupeLocalAutonome::SecretaireLocal.name.to_sym, group: groupe_local).person
    expect(Ability.new(member)).not_to be_able_to(:update, fee)
  end
end
