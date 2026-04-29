# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Eeds::EventApprover do
  let(:national) { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS Test") }
  let(:region) { Fabricate(Group::RegionEeds.sti_name, name: "Région T", parent: national) }
  let(:district) { Fabricate(Group::District.sti_name, name: "District T", parent: region) }
  let(:groupe_local) { Fabricate(Group::GroupeLocal.sti_name, name: "GL T", parent: district) }

  # Approbateurs de chaque couche.
  let!(:chef_groupe) do
    Fabricate(Group::GroupeLocal::ChefGroupe.name.to_sym, group: groupe_local).person
  end
  let!(:commissaire_district) do
    Fabricate(Group::District::CommissaireDistrict.name.to_sym, group: district).person
  end
  let!(:commissaire_regional) do
    Fabricate(Group::RegionEeds::CommissaireRegional.name.to_sym, group: region).person
  end
  let!(:commissaire_national) do
    Fabricate(Group::National::CommissaireNational.name.to_sym, group: national).person
  end

  let(:participant) do
    p = Fabricate(:person)
    Fabricate(Group::Mbootaay::Caat.name.to_sym, group: Fabricate(Group::Mbootaay.sti_name, name: "U", parent: groupe_local), person: p)
    p.update!(primary_group: groupe_local)
    p
  end

  let(:camp) do
    c = Event::Camp.new(
      name: "Camp Test", groups: [groupe_local],
      requires_approval_groupe_local: true,
      requires_approval_district: true,
      requires_approval_region: true,
      requires_approval_national: true
    )
    c.dates_attributes = [{start_at: Time.zone.today + 30, finish_at: Time.zone.today + 35}]
    c.save!
    c
  end

  let(:participation) { Fabricate(:event_participation, event: camp, participant: participant) }
  let!(:application)  { Event::Application.create!(priority_1: camp, participation: participation) }

  describe "#request_approvals (auto via concern)" do
    it "creates the first approval at the lowest required layer" do
      expect(application.approvals.pluck(:layer)).to eq(%w[groupe_local])
    end

    it "skips a layer whose flag is false" do
      camp.update!(requires_approval_groupe_local: false)
      app2 = build_fresh_application
      expect(app2.approvals.pluck(:layer)).to eq(%w[district])
    end
  end

  describe "#approve cascades through the chain" do
    it "advances to the next layer on approval and finalises at national" do
      approver = described_class.new(participation.reload)
      expect { approver.approve({comment: "ok"}, chef_groupe) }
        .to change { application.approvals.pluck(:layer).sort }
        .from(%w[groupe_local]).to(%w[district groupe_local])

      approver = described_class.new(participation.reload)
      approver.approve({comment: "ok"}, commissaire_district)

      approver = described_class.new(participation.reload)
      approver.approve({comment: "ok"}, commissaire_regional)

      approver = described_class.new(participation.reload)
      approver.approve({comment: "ok"}, commissaire_national)

      expect(application.reload.approved).to be true
      expect(application.approvals.where(approved: true).pluck(:layer))
        .to match_array(%w[groupe_local district region national])
    end
  end

  describe "#reject" do
    it "marks the open approval rejected and the application rejected" do
      approver = described_class.new(participation.reload)
      expect(approver.reject({comment: "non"}, chef_groupe)).to be true
      expect(application.reload.rejected).to be true
      expect(application.approvals.find_by(layer: "groupe_local")).to be_rejected
    end
  end

  describe "#current_approvers" do
    it "lists people holding :approve_applications at the open layer" do
      approver = described_class.new(participation.reload)
      expect(approver.current_approvers).to include(chef_groupe)
      expect(approver.current_approvers).not_to include(commissaire_district)
    end
  end

  context "Groupe Local Autonome (skips district + region)" do
    let(:gla) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GLA T", parent: national) }
    let!(:chef_gla) { Fabricate(Group::GroupeLocalAutonome::ChefGroupe.name.to_sym, group: gla).person }
    let(:participant_gla) do
      p = Fabricate(:person)
      Fabricate(Group::Mbootaay::Caat.name.to_sym,
        group: Fabricate(Group::Mbootaay.sti_name, name: "U2", parent: gla), person: p)
      p.update!(primary_group: gla)
      p
    end
    let(:camp_gla) do
      c = Event::Camp.new(
        name: "Camp GLA", groups: [gla],
        requires_approval_groupe_local: true,
        requires_approval_district: true,  # ignoré : pas de district dans la chaîne
        requires_approval_region: true,    # ignoré
        requires_approval_national: true
      )
      c.dates_attributes = [{start_at: Time.zone.today + 30, finish_at: Time.zone.today + 35}]
      c.save!
      c
    end
    let(:participation_gla) { Fabricate(:event_participation, event: camp_gla, participant: participant_gla) }

    it "follows the autonomous shortcut groupe_local → national" do
      app = Event::Application.create!(priority_1: camp_gla, participation: participation_gla)
      expect(app.approvals.pluck(:layer)).to eq(%w[groupe_local])

      described_class.new(participation_gla.reload).approve({}, chef_gla)
      expect(app.reload.approvals.where(approved: false, rejected: false).pluck(:layer))
        .to eq(%w[national])
    end
  end

  def build_fresh_application
    p = Fabricate(:person)
    Fabricate(Group::Mbootaay::Caat.name.to_sym,
      group: Fabricate(Group::Mbootaay.sti_name, name: "U#{rand(1000)}", parent: groupe_local), person: p)
    p.update!(primary_group: groupe_local)
    pa = Fabricate(:event_participation, event: camp, participant: p)
    Event::Application.create!(priority_1: camp, participation: pa)
  end
end
