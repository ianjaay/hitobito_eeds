# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Eeds::MembershipFeeGenerator do
  let(:national)    { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS Test") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL Gen", parent: national) }
  let(:mbootaay)    { Fabricate(Group::Mbootaay.sti_name, name: "M U", parent: groupe_local) }
  let(:kayon)       { Fabricate(Group::Kayon.sti_name, name: "K U", parent: groupe_local) }

  let!(:rate_jiwu) do
    MembershipFeeRate.create!(year: 2026, branche: "jiwu", amount_cents: 5_000_00, currency: "XOF")
  end
  let!(:rate_lawtan) do
    MembershipFeeRate.create!(year: 2026, branche: "lawtan", amount_cents: 6_000_00, currency: "XOF")
  end
  let!(:rate_encadrement) do
    MembershipFeeRate.create!(year: 2026, branche: "encadrement", amount_cents: 10_000_00, currency: "XOF")
  end

  let!(:caat) { Fabricate(Group::Mbootaay::Caat.name.to_sym, group: mbootaay).person }
  let!(:arunga) { Fabricate(Group::Kayon::Arunga.name.to_sym, group: kayon).person }
  let!(:chef) { Fabricate(Group::GroupeLocalAutonome::ChefGroupe.name.to_sym, group: groupe_local).person }

  subject(:generator) { described_class.new(group: groupe_local, year: 2026) }

  it "generates a fee per active member with the right branche and amount" do
    fees = generator.generate!
    expect(fees.size).to eq(3)

    by_person = fees.index_by(&:person_id)
    expect(by_person[caat.id].branche).to eq("jiwu")
    expect(by_person[caat.id].amount_cents).to eq(5_000_00)
    expect(by_person[arunga.id].branche).to eq("lawtan")
    expect(by_person[arunga.id].amount_cents).to eq(6_000_00)
    expect(by_person[chef.id].branche).to eq("encadrement")
    expect(by_person[chef.id].amount_cents).to eq(10_000_00)
  end

  it "all generated fees are pending and attached to the groupe local" do
    fees = generator.generate!
    expect(fees).to all(have_attributes(status: "pending", group_id: groupe_local.id, year: 2026))
  end

  it "skips persons who already have a fee for that year" do
    MembershipFee.create!(person: caat, group: groupe_local, year: 2026,
      branche: "jiwu", amount_cents: 5_000_00, currency: "XOF", status: "paid",
      paid_at: Time.zone.today)
    fees = generator.generate!
    expect(fees.size).to eq(2)
    expect(fees.map(&:person_id)).not_to include(caat.id)
  end

  it "records missing rates without raising" do
    rate_encadrement.destroy
    fees = generator.generate!
    expect(fees.size).to eq(2)
    expect(generator.missing_rates).to include("encadrement")
  end
end
