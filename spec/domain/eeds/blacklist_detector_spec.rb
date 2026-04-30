# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Eeds::BlacklistDetector do
  let!(:bl) do
    Blacklist.create!(first_name: "John", last_name: "Doe",
      email: "john@example.test", matricule_scout: "M-007", phone_number: "+221 77 123 45 67",
      reference_name: "Ref", reference_phone_number: "+221 77 000 00 00")
  end

  it "matches on (first_name, last_name) case-insensitive" do
    p = Person.new(first_name: "JOHN", last_name: "doe")
    expect(described_class.new(p).matches?).to be true
  end

  it "matches on email case-insensitive" do
    p = Person.new(first_name: "X", last_name: "Y", email: "JOHN@example.TEST")
    expect(described_class.new(p).matches?).to be true
  end

  it "matches on matricule_scout exact" do
    p = Person.new(first_name: "X", last_name: "Y", matricule_scout: "M-007")
    expect(described_class.new(p).matches?).to be true
  end

  it "matches on phone (last 9 digits) using parent_contact_phone for non-persisted" do
    p = Person.new(first_name: "X", last_name: "Y", parent_contact_phone: "00 221 77-123-45-67")
    expect(described_class.new(p).matches?).to be true
  end

  it "does not match an unrelated person" do
    p = Person.new(first_name: "Anna", last_name: "Sow", email: "anna@example.test")
    expect(described_class.new(p).matches?).to be false
  end

  it "returns matching records" do
    p = Person.new(first_name: "John", last_name: "Doe")
    expect(described_class.new(p).matching_records).to eq([bl])
  end
end
