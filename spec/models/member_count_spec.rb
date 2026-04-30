# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe MemberCount do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL Effectifs", parent: national) }

  it "computes per-category totals and grand total" do
    mc = described_class.create!(group: groupe_local, year: 2026,
      jiwu_f: 5, jiwu_m: 4, jiwu_u: 1,
      lawtan_f: 3, lawtan_m: 2,
      encadrement_f: 1, encadrement_m: 2)
    expect(mc.jiwu).to eq(10)
    expect(mc.lawtan).to eq(5)
    expect(mc.encadrement).to eq(3)
    expect(mc.total).to eq(18)
    expect(mc.total_f).to eq(9)
    expect(mc.total_m).to eq(8)
    expect(mc.total_u).to eq(1)
  end

  it "enforces uniqueness on group/year" do
    described_class.create!(group: groupe_local, year: 2026)
    dup = described_class.new(group: groupe_local, year: 2026)
    expect(dup).not_to be_valid
    expect(dup.errors[:group_id]).to be_present
  end

  it "rejects negative counts" do
    mc = described_class.new(group: groupe_local, year: 2026, jiwu_f: -1)
    expect(mc).not_to be_valid
    expect(mc.errors[:jiwu_f]).to be_present
  end
end
