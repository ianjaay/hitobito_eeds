# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Crisis do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL Crisis", parent: national) }
  let(:creator)      { Fabricate(:person) }

  it "is invalid without kind / severity" do
    c = described_class.new(group: groupe_local, creator: creator)
    expect(c).not_to be_valid
    expect(c.errors[:kind]).to be_present
  end

  it "rejects unknown kind/severity" do
    c = described_class.new(group: groupe_local, creator: creator, kind: "ufo", severity: "hot")
    expect(c).not_to be_valid
    expect(c.errors[:kind]).to be_present
    expect(c.errors[:severity]).to be_present
  end

  it "is valid with kind/severity in allowed lists" do
    c = described_class.new(group: groupe_local, creator: creator, kind: "accident", severity: "high")
    expect(c).to be_valid
  end

  it "rejects a second active crisis on the same group" do
    described_class.create!(group: groupe_local, creator: creator, kind: "accident", severity: "medium")
    second = described_class.new(group: groupe_local, creator: creator, kind: "abus", severity: "high")
    expect(second).not_to be_valid
    expect(second.errors[:base]).to be_present
  end

  it "allows a new crisis once the previous one is completed" do
    first = described_class.create!(group: groupe_local, creator: creator, kind: "accident", severity: "low")
    first.complete!(creator)
    second = described_class.new(group: groupe_local, creator: creator, kind: "abus", severity: "high")
    expect(second).to be_valid
  end

  it "transitions through pending → acknowledged → completed" do
    c = described_class.create!(group: groupe_local, creator: creator, kind: "accident", severity: "medium")
    expect(c.status).to eq(:pending)
    c.acknowledge!(creator)
    expect(c.reload.status).to eq(:acknowledged)
    c.complete!(creator)
    expect(c.reload.status).to eq(:completed)
  end

  it "acknowledge! returns false on a completed crisis" do
    c = described_class.create!(group: groupe_local, creator: creator, kind: "accident", severity: "low")
    c.complete!(creator)
    expect(c.acknowledge!(creator)).to be false
  end
end
