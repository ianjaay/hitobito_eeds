# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe MembershipFeeRate do
  it "is valid with required attributes" do
    rate = MembershipFeeRate.new(year: 2026, branche: "jiwu", amount_cents: 5_000_00, currency: "XOF")
    expect(rate).to be_valid
  end

  it "enforces uniqueness on (year, branche)" do
    MembershipFeeRate.create!(year: 2026, branche: "jiwu", amount_cents: 5_000_00, currency: "XOF")
    dup = MembershipFeeRate.new(year: 2026, branche: "jiwu", amount_cents: 6_000_00, currency: "XOF")
    expect(dup).not_to be_valid
  end

  describe ".lookup" do
    let!(:rate) { MembershipFeeRate.create!(year: 2026, branche: "lawtan", amount_cents: 7_000_00, currency: "XOF") }

    it "returns the rate for the given year and branche" do
      expect(MembershipFeeRate.lookup(2026, "lawtan")).to eq(rate)
    end

    it "returns nil when no rate exists" do
      expect(MembershipFeeRate.lookup(2026, "menneef")).to be_nil
    end
  end
end
