# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Event::Approval do
  let(:national) { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS Test") }
  let(:groupe_local) do
    region = Fabricate(Group::RegionEeds.sti_name, name: "Région Test", parent: national)
    district = Fabricate(Group::District.sti_name, name: "District Test", parent: region)
    Fabricate(Group::GroupeLocal.sti_name, name: "Groupe Test", parent: district)
  end
  let(:camp) do
    c = Event::Camp.new(name: "Camp Test", groups: [groupe_local])
    c.dates_attributes = [{start_at: Time.zone.today, finish_at: Time.zone.today + 5}]
    c.save!
    c
  end
  let(:person) { Fabricate(:person) }
  let(:participation) do
    Fabricate(:event_participation, event: camp, person: person)
  end
  let(:application) { Event::Application.create!(priority_1: camp, participation: participation) }

  it "exposes the four EEDS layers in hierarchical order" do
    expect(described_class::LAYERS).to eq(%w[groupe_local district region national])
  end

  describe "validations" do
    it "requires a known layer" do
      approval = described_class.new(application: application, layer: "bogus")
      expect(approval).not_to be_valid
      expect(approval.errors[:layer]).to be_present
    end

    it "is unique per (application, layer)" do
      described_class.create!(application: application, layer: "district")
      dup = described_class.new(application: application, layer: "district")
      expect(dup).not_to be_valid
    end

    it "rejects approved AND rejected at the same time" do
      approval = described_class.new(
        application: application, layer: "district", approved: true, rejected: true
      )
      expect(approval).not_to be_valid
      expect(approval.errors[:base]).to be_present
    end
  end

  describe "#status" do
    it "is :pending by default" do
      expect(described_class.new.status).to eq(:pending)
    end

    it "is :approved once approved" do
      expect(described_class.new(approved: true).status).to eq(:approved)
    end

    it "is :rejected once rejected" do
      expect(described_class.new(rejected: true).status).to eq(:rejected)
    end
  end

  describe "#layer_class" do
    {
      "groupe_local" => Group::GroupeLocal,
      "district"     => Group::District,
      "region"       => Group::RegionEeds,
      "national"     => Group::National
    }.each do |layer, klass|
      it "maps #{layer} → #{klass}" do
        expect(described_class.new(layer: layer).layer_class).to eq(klass)
      end
    end
  end

  describe ".order_by_layer" do
    it "orders rows in hierarchical order" do
      %w[national groupe_local region district].each do |l|
        described_class.create!(application: application, layer: l)
      end
      expect(described_class.order_by_layer.pluck(:layer))
        .to eq(%w[groupe_local district region national])
    end
  end
end
