# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Event::ApprovalsController do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }
  let(:region)       { Fabricate(Group::RegionEeds.sti_name, name: "Région X", parent: national) }
  let(:district)     { Fabricate(Group::District.sti_name, name: "District X", parent: region) }
  let(:groupe_local) { Fabricate(Group::GroupeLocal.sti_name, name: "GL X", parent: district) }
  let(:mbootaay)     { Fabricate(Group::Mbootaay.sti_name, name: "U", parent: groupe_local) }

  let!(:chef_groupe) { Fabricate(Group::GroupeLocal::ChefGroupe.name.to_sym, group: groupe_local).person }
  let!(:commissaire_district) { Fabricate(Group::District::CommissaireDistrict.name.to_sym, group: district).person }

  let(:participant) do
    p = Fabricate(:person)
    Fabricate(Group::Mbootaay::Caat.name.to_sym, group: mbootaay, person: p)
    p.update!(primary_group: groupe_local)
    p
  end

  let(:camp) do
    c = Event::Camp.new(name: "Camp Y", groups: [groupe_local],
      requires_approval_groupe_local: true,
      requires_approval_district: true)
    c.dates_attributes = [{start_at: Time.zone.today + 30, finish_at: Time.zone.today + 35}]
    c.save!
    c
  end

  let(:participation) { Fabricate(:event_participation, event: camp, participant: participant, active: true) }
  let!(:application)  { Event::Application.create!(priority_1: camp, participation: participation) }

  describe "POST create" do
    it "approves and cascades to district" do
      sign_in(chef_groupe)
      post :create,
        params: {group_id: groupe_local.id, event_id: camp.id, participation_id: participation.id,
                 decision: "approve", event_approval: {comment: "OK"}}

      expect(response).to redirect_to(group_event_participation_path(groupe_local, camp, participation))
      expect(application.reload.approvals.where(approved: true).pluck(:layer)).to eq(%w[groupe_local])
      expect(application.approvals.where(approved: false, rejected: false).pluck(:layer)).to eq(%w[district])
    end

    it "rejects with comment" do
      sign_in(chef_groupe)
      post :create,
        params: {group_id: groupe_local.id, event_id: camp.id, participation_id: participation.id,
                 decision: "reject", event_approval: {comment: "Non"}}

      expect(application.reload.rejected).to be true
      expect(application.approvals.find_by(layer: "groupe_local")).to be_rejected
    end

    it "denies a user without :approve_applications permission" do
      sign_in(participant)
      expect do
        post :create,
          params: {group_id: groupe_local.id, event_id: camp.id, participation_id: participation.id,
                   decision: "approve", event_approval: {comment: ""}}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "GET index" do
    it "lists approvals grouped by participation" do
      sign_in(chef_groupe)
      get :index, params: {group_id: groupe_local.id, event_id: camp.id}
      expect(response).to be_successful
      expect(assigns(:approvals).keys.map(&:id)).to include(participation.id)
    end
  end
end
