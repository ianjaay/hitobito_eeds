# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe BlacklistsController do
  let(:national)    { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }
  let(:admin)       { Fabricate(Group::National::CommissaireNational.name.to_sym, group: national).person }
  let(:outsider)    { Fabricate(:person) }

  it "POST create by admin adds an entry" do
    sign_in(admin)
    expect do
      post :create, params: {blacklist: {first_name: "John", last_name: "Doe",
        reference_name: "Adj", reference_phone_number: "+221 77 000 00 00"}}
    end.to change { Blacklist.count }.by(1)
    expect(response).to redirect_to(blacklists_path)
    expect(Blacklist.last.created_by).to eq(admin)
  end

  it "GET index denied for non-admin" do
    sign_in(outsider)
    expect { get :index }.to raise_error(CanCan::AccessDenied)
  end
end
