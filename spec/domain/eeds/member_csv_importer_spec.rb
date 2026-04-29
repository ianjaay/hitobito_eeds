# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Eeds::MemberCsvImporter do
  let(:national) do
    Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS")
  end
  let(:gla) do
    Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GLA Test", parent: national)
  end
  let(:mbootaay) do
    Fabricate(Group::Mbootaay.sti_name, name: "Mbootaay Test", parent: gla)
  end

  let(:full_headers) do
    %w[matricule_scout last_name first_name gender birthday branche group_id email
       parent_contact_name parent_contact_phone parent_contact_email]
  end

  def csv(rows, headers: full_headers)
    [headers.join(","), *rows.map { |r| headers.map { |h| r[h] }.join(",") }].join("\n")
  end

  let(:valid_row) do
    {
      "matricule_scout" => "EEDS-001",
      "last_name" => "Diop",
      "first_name" => "Awa",
      "gender" => "w",
      "birthday" => "2015-03-12",
      "branche" => "mbootaay",
      "group_id" => mbootaay.id.to_s,
      "email" => "awa+#{SecureRandom.hex(3)}@eeds.test",
      "parent_contact_name" => "Mariama Diop",
      "parent_contact_phone" => "+221 77 123 45 67",
      "parent_contact_email" => "mariama@eeds.test"
    }
  end

  describe "#dry_run" do
    it "returns a successful result for a valid row without persisting" do
      result = described_class.new(csv([valid_row])).dry_run

      expect(result).to be_success
      expect(result.created.size).to eq(1)
      expect(result.updated).to be_empty
      expect(Person.where(matricule_scout: "EEDS-001")).to be_empty
    end

    it "reports missing required headers" do
      headers = %w[last_name first_name branche group_id]
      content = [headers.join(","), "Diop,Awa,mbootaay,#{mbootaay.id}"].join("\n")

      result = described_class.new(content).dry_run

      expect(result).not_to be_success
      expect(result.errors.first.messages.first).to match(/matricule_scout/)
    end

    it "reports unknown group_id" do
      row = valid_row.merge("group_id" => "999999999")
      result = described_class.new(csv([row])).dry_run

      expect(result).not_to be_success
      expect(result.errors.first.messages.first).to match(/Groupe introuvable/)
    end

    it "reports invalid branche value" do
      row = valid_row.merge("branche" => "invalide")
      result = described_class.new(csv([row])).dry_run

      expect(result).not_to be_success
      expect(result.errors.first.messages.join).to match(/branche/i)
    end

    it "matches existing matricule and lists the row as updated" do
      Fabricate(:person, matricule_scout: "EEDS-001",
        first_name: "Existing", last_name: "Person",
        email: "existing@eeds.test")

      row = valid_row.merge(
        "matricule_scout" => "EEDS-001",
        "first_name" => "NewFirst",
        "email" => "different@eeds.test"
      )

      result = described_class.new(csv([row])).dry_run

      expect(result).to be_success
      expect(result.updated.size).to eq(1)
      expect(result.created).to be_empty
    end
  end

  describe "#commit" do
    it "creates the person and assigns the standard role of the target group" do
      mbootaay
      expect {
        described_class.new(csv([valid_row])).commit
      }.to change { Person.count }.by(1)

      person = Person.find_by(matricule_scout: "EEDS-001")
      expect(person).to be_present
      expect(person.branche).to eq("mbootaay")
      expect(person.parent_contact_phone).to eq("+221 77 123 45 67")
      expect(person.roles.where(group_id: mbootaay.id, type: Group::Mbootaay::Caat.sti_name)).to exist
    end

    it "rolls back the entire transaction when any row is invalid" do
      good_row = valid_row.merge("matricule_scout" => "EEDS-002",
        "first_name" => "Mor", "email" => "mor@eeds.test")
      broken_row = valid_row.merge("matricule_scout" => "EEDS-003",
        "first_name" => "Cheikh", "email" => "cheikh@eeds.test",
        "group_id" => "999999999")

      expect {
        described_class.new(csv([good_row, broken_row])).commit
      }.not_to change { Person.count }

      expect(Person.where(matricule_scout: "EEDS-002")).to be_empty
    end
  end
end
