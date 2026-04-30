# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Eeds::MemberCountGenerator do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL Comptage", parent: national) }
  let(:mbootaay)     { Fabricate(Group::Mbootaay.sti_name, name: "M U", parent: groupe_local) }
  let(:kayon)        { Fabricate(Group::Kayon.sti_name, name: "K U", parent: groupe_local) }

  let!(:caat_f) do
    person = Fabricate(:person, gender: "w")
    Fabricate(Group::Mbootaay::Caat.name.to_sym, group: mbootaay, person: person)
    person
  end
  let!(:caat_m) do
    person = Fabricate(:person, gender: "m")
    Fabricate(Group::Mbootaay::Caat.name.to_sym, group: mbootaay, person: person)
    person
  end
  let!(:njiit) do
    person = Fabricate(:person, gender: "w")
    Fabricate(Group::Mbootaay::Njiit.name.to_sym, group: mbootaay, person: person)
    person
  end
  let!(:arunga) do
    person = Fabricate(:person, gender: nil)
    Fabricate(Group::Kayon::Arunga.name.to_sym, group: kayon, person: person)
    person
  end
  let!(:chef_groupe) do
    person = Fabricate(:person, gender: "m")
    Fabricate(Group::GroupeLocalAutonome::ChefGroupe.name.to_sym, group: groupe_local, person: person)
    person
  end

  subject(:gen) { described_class.new(group: groupe_local, year: 2026) }

  it "counts members by branche × gender and persists a MemberCount" do
    mc = gen.run!
    expect(mc).to be_persisted
    expect(mc.year).to eq(2026)
    expect(mc.group).to eq(groupe_local)

    # Mbootaay → jiwu : 1F (caat_f) + 1M (caat_m) + 1F encadrement (njiit)
    expect(mc.jiwu_f).to eq(1)
    expect(mc.jiwu_m).to eq(1)
    expect(mc.jiwu_u).to eq(0)

    # Kayon → lawtan : 1U (arunga sans genre)
    expect(mc.lawtan_u).to eq(1)
    expect(mc.lawtan_f).to eq(0)
    expect(mc.lawtan_m).to eq(0)

    # Encadrement : Njiit (Mbootaay non-standard) + ChefGroupe (Groupe Local)
    expect(mc.encadrement_f).to eq(1)
    expect(mc.encadrement_m).to eq(1)
  end

  it "is idempotent: re-running upserts the same row" do
    first  = gen.run!
    second = gen.run!
    expect(second.id).to eq(first.id)
    expect(MemberCount.where(group: groupe_local, year: 2026).count).to eq(1)
  end

  it "links to a Census when one is provided" do
    census = Census.create!(year: 2026, start_at: Date.new(2026, 1, 1))
    mc = described_class.new(group: groupe_local, year: 2026, census: census).run!
    expect(mc.census).to eq(census)
  end
end
