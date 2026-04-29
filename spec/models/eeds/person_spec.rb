# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Eeds::Person do
  let(:national) { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS Test") }
  let(:base_attrs) do
    {
      first_name: "Awa",
      last_name: "Diop",
      email: "awa.diop+#{SecureRandom.hex(4)}@eeds.test"
    }
  end

  it "is included in Person" do
    expect(Person.included_modules).to include(described_class)
  end

  it "exposes the four EEDS branches as enum values" do
    expect(described_class::BRANCHES).to eq(%w[mbootaay kayon nawka galle])
  end

  describe "branche enum" do
    it "accepts valid values" do
      Eeds::Person::BRANCHES.each do |b|
        person = Person.new(base_attrs.merge(branche: b))
        person.valid?
        expect(person.errors[:branche]).to be_empty, "expected '#{b}' to be valid"
      end
    end

    it "rejects unknown values" do
      person = Person.new(base_attrs.merge(branche: "unknown"))
      person.valid?
      expect(person.errors[:branche]).not_to be_empty
    end

    it "allows blank" do
      person = Person.new(base_attrs)
      person.valid?
      expect(person.errors[:branche]).to be_empty
    end

    it "produces translated labels" do
      I18n.with_locale(:fr) do
        labels = Person.branche_labels
        expect(labels[:mbootaay]).to eq("Mbootaay")
        expect(labels[:nawka]).to eq("Ñawka")
        expect(labels[:galle]).to eq("Gàlle")
      end
    end

    it "scopes Person by branche" do
      expect(Person).to respond_to(:mbootaay)
      expect(Person.mbootaay.to_sql).to include("'mbootaay'")
    end
  end

  describe "matricule_scout uniqueness" do
    let(:matricule) { "EEDS-#{SecureRandom.hex(4).upcase}" }

    it "rejects duplicates regardless of case" do
      Person.create!(base_attrs.merge(matricule_scout: matricule))
      dup = Person.new(base_attrs.merge(
        email: "dup+#{SecureRandom.hex(4)}@eeds.test",
        matricule_scout: matricule.downcase
      ))
      expect(dup).not_to be_valid
      expect(dup.errors[:matricule_scout]).not_to be_empty
    end

    it "allows multiple records with blank matricule" do
      Person.create!(base_attrs.merge(matricule_scout: nil))
      other = Person.new(base_attrs.merge(
        email: "other+#{SecureRandom.hex(4)}@eeds.test",
        matricule_scout: nil
      ))
      expect(other).to be_valid
    end
  end

  describe "parent contact" do
    it "validates phone format softly" do
      person = Person.new(base_attrs.merge(parent_contact_phone: "+221 77 123 45 67"))
      person.valid?
      expect(person.errors[:parent_contact_phone]).to be_empty
    end

    it "rejects malformed phone" do
      person = Person.new(base_attrs.merge(parent_contact_phone: "abc"))
      person.valid?
      expect(person.errors[:parent_contact_phone]).not_to be_empty
    end

    it "validates email format" do
      person = Person.new(base_attrs.merge(parent_contact_email: "not-an-email"))
      person.valid?
      expect(person.errors[:parent_contact_email]).not_to be_empty
    end

    it "#parent_contact? returns true when any field present" do
      person = Person.new(base_attrs.merge(parent_contact_name: "Maman Diop"))
      expect(person.parent_contact?).to be true
    end

    it "#parent_contact? returns false when all blank" do
      person = Person.new(base_attrs)
      expect(person.parent_contact?).to be false
    end

    it "#parent_contact_summary joins fields with bullets" do
      person = Person.new(base_attrs.merge(
        parent_contact_name: "Maman Diop",
        parent_contact_phone: "+221770000000"
      ))
      expect(person.parent_contact_summary).to eq("Maman Diop • +221770000000")
    end
  end

  describe "EEDS columns persistence" do
    it "round-trips all custom attributes" do
      attrs = base_attrs.merge(
        matricule_scout: "EEDS-PERSIST-001",
        branche: "kayon",
        unite: "Patrouille des Lions",
        assurance_expiration: Date.new(2027, 1, 1),
        progression_badges: "Badge cuisine, badge nature",
        parent_contact_name: "Père Diop",
        parent_contact_phone: "+221 77 555 12 34",
        parent_contact_email: "pere.diop@example.com",
        profession: "Enseignant",
        competences: "Wolof, français, anglais ; secourisme"
      )
      person = Person.create!(attrs)
      person.reload
      attrs.each { |k, v| expect(person.send(k)).to eq(v) }
    end
  end

  describe "branche colors" do
    it "exposes the official branch color hex per branche value" do
      expect(Eeds::Person::BRANCH_COLORS).to eq({
        "mbootaay" => "#fdef42",
        "kayon"    => "#00853f",
        "nawka"    => "#ffffff",
        "galle"    => "#e31b23"
      })
    end

    it "returns the color for a person's branche" do
      person = Person.new(base_attrs.merge(branche: "galle"))
      expect(person.branche_color).to eq("#e31b23")
      expect(person.branche_color_name).to eq("rouge")
    end

    it "returns nil when no branche is set" do
      person = Person.new(base_attrs)
      expect(person.branche_color).to be_nil
      expect(person.branche_color_name).to be_nil
    end

    it "matches the BRANCH_COLOR exposed by each branche group class" do
      expect(Group::Mbootaay.branch_color).to eq(Eeds::Person::BRANCH_COLORS["mbootaay"])
      expect(Group::Kayon.branch_color).to eq(Eeds::Person::BRANCH_COLORS["kayon"])
      expect(Group::Nawka.branch_color).to eq(Eeds::Person::BRANCH_COLORS["nawka"])
      expect(Group::Galle.branch_color).to eq(Eeds::Person::BRANCH_COLORS["galle"])
    end
  end
end
