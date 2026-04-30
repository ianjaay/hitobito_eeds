# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe CrisesController do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL UI", parent: national) }
  let(:chef_groupe)  { Fabricate(Group::GroupeLocalAutonome::ChefGroupe.name.to_sym, group: groupe_local).person }
  let(:commissaire)  { Fabricate(Group::National::CommissaireNational.name.to_sym, group: national).person }

  it "POST create triggers a crisis and notifies" do
    sign_in(chef_groupe)
    expect do
      post :create, params: {group_id: groupe_local.id,
        crisis: {kind: "accident", severity: "high", description: "chute"}}
    end.to change { Crisis.count }.by(1)
    expect(response).to redirect_to(group_crises_path(groupe_local))
  end

  it "POST create denied for outsider" do
    sign_in(Fabricate(:person))
    expect do
      post :create, params: {group_id: groupe_local.id,
        crisis: {kind: "accident", severity: "high"}}
    end.to raise_error(CanCan::AccessDenied)
  end

  it "PATCH acknowledge by upper-layer commissaire" do
    crisis = Crisis.create!(group: groupe_local, creator: chef_groupe,
      kind: "accident", severity: "medium")
    sign_in(commissaire)
    patch :acknowledge, params: {group_id: groupe_local.id, id: crisis.id}
    expect(crisis.reload.acknowledged).to be true
  end

  it "PATCH complete closes the crisis" do
    crisis = Crisis.create!(group: groupe_local, creator: chef_groupe,
      kind: "abus", severity: "critical")
    sign_in(commissaire)
    patch :complete, params: {group_id: groupe_local.id, id: crisis.id}
    expect(crisis.reload.completed).to be true
  end
end
