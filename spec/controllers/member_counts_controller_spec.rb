# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe MemberCountsController do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL UI", parent: national) }
  let(:mbootaay)     { Fabricate(Group::Mbootaay.sti_name, name: "M U", parent: groupe_local) }

  let(:chef_groupe) { Fabricate(Group::GroupeLocalAutonome::ChefGroupe.name.to_sym, group: groupe_local).person }
  let(:outsider)    { Fabricate(:person) }

  before do
    Fabricate(Group::Mbootaay::Caat.name.to_sym, group: mbootaay,
      person: Fabricate(:person, gender: "w"))
  end

  it "GET index renders for ChefGroupe" do
    sign_in(chef_groupe)
    get :index, params: {group_id: groupe_local.id, year: 2026}
    expect(response).to be_successful
  end

  it "GET index forbidden for outsider" do
    sign_in(outsider)
    expect do
      get :index, params: {group_id: groupe_local.id, year: 2026}
    end.to raise_error(CanCan::AccessDenied)
  end

  it "POST recompute creates a MemberCount and redirects" do
    sign_in(chef_groupe)
    expect do
      post :recompute, params: {group_id: groupe_local.id, year: 2026}
    end.to change { MemberCount.where(group: groupe_local, year: 2026).count }.from(0).to(1)
    expect(response).to redirect_to(group_member_counts_path(groupe_local, year: 2026))
  end

  it "PATCH update changes counts manually" do
    sign_in(chef_groupe)
    mc = MemberCount.create!(group: groupe_local, year: 2026)
    patch :update, params: {group_id: groupe_local.id, id: mc.id,
      member_count: {jiwu_f: 7, jiwu_m: 5}}
    expect(mc.reload.jiwu_f).to eq(7)
    expect(mc.jiwu_m).to eq(5)
  end
end
