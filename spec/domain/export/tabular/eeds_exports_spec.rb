# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"
require "csv"

describe "Eeds CSV exports" do
  let(:national)    { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS T") }
  let(:gl)          { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GLA Exp", parent: national) }
  let(:mb)          { Fabricate(Group::Mbootaay.sti_name, name: "Unité Mbootaay", parent: gl) }

  describe Export::Tabular::MembershipFees::List do
    it "produces a CSV with headers and a data row" do
      person = Fabricate(:person, first_name: "Awa", last_name: "Diop")
      fee = MembershipFee.create!(person: person, group: gl, year: 2026, branche: "jiwu",
        amount_cents: 5_000_00, currency: "XOF", status: "pending")
      csv = CSV.parse(described_class.csv([fee]), col_sep: Settings.csv.separator.strip)
      expect(csv.size).to eq(2)
      expect(csv.first.join(",")).to match(/Year|Année|Jahr/i)
      expect(csv.last).to include("2026")
      expect(csv.last.join(",")).to include("Awa Diop")
    end
  end

  describe Export::Tabular::MemberCounts::List do
    it "produces a CSV with category columns" do
      mc = MemberCount.create!(group: gl, year: 2026, jiwu_f: 3, jiwu_m: 2)
      csv = CSV.parse(described_class.csv([mc]), col_sep: Settings.csv.separator.strip)
      expect(csv.size).to eq(2)
      expect(csv.last).to include("2026")
      expect(csv.last).to include("3")
      expect(csv.last).to include("5") # total
    end
  end

  describe Export::Tabular::Crises::List do
    it "produces a CSV with status" do
      person = Fabricate(:person)
      c = Crisis.create!(creator: person, group: gl, kind: "accident", severity: "high",
        description: "x")
      csv = CSV.parse(described_class.csv([c]), col_sep: Settings.csv.separator.strip)
      expect(csv.size).to eq(2)
      expect(csv.last).to include("pending")
      expect(csv.last).to include("accident")
    end
  end

  describe Export::Tabular::Blacklists::List do
    it "produces a CSV with blacklist columns" do
      bl = Blacklist.create!(first_name: "Mamadou", last_name: "Sow",
        reason: "test", reference_name: "Ref", reference_phone_number: "770000000")
      csv = CSV.parse(described_class.csv([bl]), col_sep: Settings.csv.separator.strip)
      expect(csv.size).to eq(2)
      expect(csv.last).to include("Sow")
      expect(csv.last).to include("Mamadou")
    end
  end
end
