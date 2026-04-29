# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Event::Camp do
  let(:national) { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS Test") }
  let(:groupe_local) do
    region = Fabricate(Group::RegionEeds.sti_name, name: "Région Test", parent: national)
    district = Fabricate(Group::District.sti_name, name: "District Test", parent: region)
    Fabricate(Group::GroupeLocal.sti_name, name: "Groupe Test", parent: district)
  end

  it "is a STI subclass of Event" do
    expect(described_class.ancestors).to include(Event)
    expect(described_class < Event).to be true
  end

  it "exposes the EEDS branches in fixed order" do
    expect(described_class::EXPECTED_PARTICIPANT_BRANCHES)
      .to eq(%w[jiwu lawtan toor_toor menneef encadrement])
  end

  it "exposes the four approval layers in hierarchical order" do
    expect(described_class::APPROVAL_LAYERS)
      .to eq(%w[groupe_local district region national])
  end

  it "registers all expected_participant_attrs (10 columns: 5 branches × 2 sexes)" do
    expect(described_class.expected_participant_attrs.size).to eq(10)
  end

  it "includes camp + approval columns in used_attributes" do
    %i[camp_location camp_emergency_phone camp_owner camp_submitted
      requires_approval_groupe_local requires_approval_national
      expected_participants_jiwu_f expected_participants_encadrement_m].each do |attr|
      expect(described_class.used_attributes).to include(attr), "missing #{attr}"
    end
  end

  describe "#total_expected_participants" do
    it "sums all expected participants across branches and sexes" do
      camp = described_class.new(
        name: "Camp d'été",
        expected_participants_jiwu_f: 5,
        expected_participants_jiwu_m: 4,
        expected_participants_lawtan_f: 3,
        expected_participants_encadrement_m: 2
      )
      expect(camp.total_expected_participants).to eq(14)
    end

    it "treats nils as zero" do
      expect(described_class.new(name: "X").total_expected_participants).to eq(0)
    end
  end

  describe "#required_approval_layers" do
    it "returns only the layers whose flag is set, in canonical order" do
      camp = described_class.new(
        name: "Camp X",
        requires_approval_groupe_local: true,
        requires_approval_region: true,
        requires_approval_national: true
      )
      expect(camp.required_approval_layers).to eq(%w[groupe_local region national])
    end

    it "is empty by default" do
      expect(described_class.new(name: "X").required_approval_layers).to eq([])
    end
  end

  it "is a valid event_type for Group::GroupeLocal" do
    expect(Group::GroupeLocal.event_types).to include(described_class)
  end

  it "is a valid event_type for Group::National" do
    expect(Group::National.event_types).to include(described_class)
  end

  it "can be persisted attached to a Groupe Local" do
    camp = described_class.new(
      name: "Camp pilote", groups: [groupe_local],
      camp_location: "Popenguine", camp_emergency_phone: "+221 33 000 00 00"
    )
    camp.dates_attributes = [{start_at: Time.zone.today, finish_at: Time.zone.today + 5}]
    expect(camp.save).to be(true), camp.errors.full_messages.join(", ")
    expect(camp.reload.camp_location).to eq("Popenguine")
  end
end
