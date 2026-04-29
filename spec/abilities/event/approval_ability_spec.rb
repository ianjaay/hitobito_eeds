# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Event::ApprovalAbility do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS Test") }
  let(:region)       { Fabricate(Group::RegionEeds.sti_name, name: "Région A", parent: national) }
  let(:district)     { Fabricate(Group::District.sti_name, name: "District A", parent: region) }
  let(:groupe_local) { Fabricate(Group::GroupeLocal.sti_name, name: "GL A", parent: district) }
  let(:mbootaay)     { Fabricate(Group::Mbootaay.sti_name, name: "U", parent: groupe_local) }

  let!(:chef_groupe) do
    Fabricate(Group::GroupeLocal::ChefGroupe.name.to_sym, group: groupe_local).person
  end
  let!(:tresorier_local) do
    Fabricate(Group::GroupeLocal::TresorierLocal.name.to_sym, group: groupe_local).person
  end
  let!(:commissaire_district) do
    Fabricate(Group::District::CommissaireDistrict.name.to_sym, group: district).person
  end

  let(:participant) do
    p = Fabricate(:person)
    Fabricate(Group::Mbootaay::Caat.name.to_sym, group: mbootaay, person: p)
    p.update!(primary_group: groupe_local)
    p
  end

  let(:camp) do
    c = Event::Camp.new(
      name: "Camp", groups: [groupe_local],
      requires_approval_groupe_local: true,
      requires_approval_district: true,
      requires_approval_region: false,
      requires_approval_national: false
    )
    c.dates_attributes = [{start_at: Time.zone.today + 30, finish_at: Time.zone.today + 35}]
    c.save!
    c
  end

  let(:participation) { Fabricate(:event_participation, event: camp, participant: participant) }
  let!(:application)  { Event::Application.create!(priority_1: camp, participation: participation) }
  let(:approval)      { application.approvals.find_by(layer: "groupe_local") }

  describe "groupe_local approval" do
    it "is updatable by ChefGroupe of the candidate's groupe_local" do
      expect(Ability.new(chef_groupe)).to be_able_to(:update, approval)
    end

    it "is not updatable by TresorierLocal (no :approve_applications permission)" do
      expect(Ability.new(tresorier_local)).not_to be_able_to(:update, approval)
    end

    it "is not updatable by CommissaireDistrict (wrong layer)" do
      expect(Ability.new(commissaire_district)).not_to be_able_to(:update, approval)
    end

    it "is not updatable once the camp has started" do
      camp.dates.first.update_columns(start_at: Time.zone.today - 1, finish_at: Time.zone.today + 1)
      expect(Ability.new(chef_groupe)).not_to be_able_to(:update, approval.reload)
    end

    it "is not updatable once already approved" do
      approval.update!(approved: true, approver: chef_groupe, approved_at: Time.zone.now)
      expect(Ability.new(chef_groupe)).not_to be_able_to(:update, approval)
    end
  end
end
