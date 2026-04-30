# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Blacklist do
  let(:base) do
    {first_name: "John", last_name: "Doe",
     reference_name: "Adj. National", reference_phone_number: "+221 77 000 00 00"}
  end

  it "is invalid without first/last name and reference" do
    expect(described_class.new).not_to be_valid
  end

  it "is valid with required fields" do
    expect(described_class.new(base)).to be_valid
  end

  it "rejects malformed email" do
    bl = described_class.new(base.merge(email: "not-an-email"))
    expect(bl).not_to be_valid
    expect(bl.errors[:email]).to be_present
  end

  it "enforces matricule_scout uniqueness" do
    described_class.create!(base.merge(matricule_scout: "M-001"))
    dup = described_class.new(base.merge(first_name: "Jane", matricule_scout: "M-001"))
    expect(dup).not_to be_valid
    expect(dup.errors[:matricule_scout]).to be_present
  end

  it "search_by matches across multiple columns" do
    described_class.create!(base.merge(email: "john@example.test"))
    described_class.create!(base.merge(first_name: "Jane", last_name: "Smith"))
    expect(described_class.search_by("smith").map(&:last_name)).to eq(["Smith"])
    expect(described_class.search_by("example").size).to eq(1)
  end
end
