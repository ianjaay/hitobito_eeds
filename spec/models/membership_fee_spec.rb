# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe MembershipFee do
  let(:national) { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS Test") }
  let(:gl) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL Fee", parent: national) }
  let(:person) { Fabricate(:person) }

  def build_fee(attrs = {})
    MembershipFee.new({
      person: person, group: gl, year: 2026,
      branche: "jiwu", amount_cents: 5_000_00, currency: "XOF", status: "pending"
    }.merge(attrs))
  end

  it "is valid with required attributes" do
    expect(build_fee).to be_valid
  end

  it "requires branche to be in BRANCHES list" do
    expect(build_fee(branche: "wrong")).not_to be_valid
  end

  it "requires status to be in STATUSES list" do
    expect(build_fee(status: "frozen")).not_to be_valid
  end

  it "enforces uniqueness on (person, year)" do
    build_fee.save!
    duplicate = build_fee
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:person_id]).to be_present
  end

  it "requires paid_at when status is paid" do
    fee = build_fee(status: "paid", paid_at: nil)
    expect(fee).not_to be_valid
  end

  describe "#mark_paid!" do
    it "transitions to paid and sets paid_at + payment_method" do
      fee = build_fee
      fee.save!
      fee.mark_paid!(method: "mobile_money", recorded_by: person, reference: "MM-001")
      expect(fee.reload).to be_paid
      expect(fee.paid_at).to be_present
      expect(fee.payment_method).to eq("mobile_money")
      expect(fee.reference).to eq("MM-001")
    end
  end

  describe "#mark_exempted!" do
    it "transitions to exempted" do
      fee = build_fee
      fee.save!
      fee.mark_exempted!(recorded_by: person, comment: "boursier")
      expect(fee.reload.status).to eq("exempted")
      expect(fee.comment).to eq("boursier")
    end
  end

  describe "#cancel!" do
    it "transitions to cancelled" do
      fee = build_fee
      fee.save!
      fee.cancel!(recorded_by: person)
      expect(fee.reload.status).to eq("cancelled")
    end
  end

  describe "scopes" do
    let!(:pending) { build_fee.tap(&:save!) }
    let!(:paid) do
      p2 = Fabricate(:person)
      MembershipFee.create!(person: p2, group: gl, year: 2026, branche: "lawtan",
        amount_cents: 6_000_00, currency: "XOF", status: "paid", paid_at: Time.zone.today)
    end

    it "filters by year" do
      expect(MembershipFee.for_year(2026)).to include(pending, paid)
    end

    it "filters outstanding (pending only)" do
      expect(MembershipFee.outstanding).to include(pending)
      expect(MembershipFee.outstanding).not_to include(paid)
    end
  end
end
