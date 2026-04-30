# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe MembershipFeesController do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL F", parent: national) }
  let(:mbootaay)     { Fabricate(Group::Mbootaay.sti_name, name: "U", parent: groupe_local) }
  let(:tresorier)    { Fabricate(Group::GroupeLocalAutonome::TresorierLocal.name.to_sym, group: groupe_local).person }
  let!(:caat)        { Fabricate(Group::Mbootaay::Caat.name.to_sym, group: mbootaay).person }
  let!(:rate)        { MembershipFeeRate.create!(year: 2026, branche: "jiwu", amount_cents: 5_000_00, currency: "XOF") }

  describe "GET index" do
    it "lists fees for the current year" do
      MembershipFee.create!(person: caat, group: groupe_local, year: 2026,
        branche: "jiwu", amount_cents: 5_000_00, currency: "XOF", status: "pending")
      sign_in(tresorier)
      get :index, params: {group_id: groupe_local.id, year: 2026}

      expect(response).to be_successful
      expect(assigns(:fees).map(&:branche)).to eq(%w[jiwu])
    end

    it "denies access to non-finance member" do
      member = Fabricate(Group::GroupeLocalAutonome::SecretaireLocal.name.to_sym, group: groupe_local).person
      sign_in(member)
      expect {
        get :index, params: {group_id: groupe_local.id, year: 2026}
      }.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "POST generate" do
    it "creates fees for active members" do
      sign_in(tresorier)
      expect {
        post :generate, params: {group_id: groupe_local.id, year: 2026}
      }.to change(MembershipFee, :count).by_at_least(1)
      expect(response).to redirect_to(group_membership_fees_path(groupe_local, year: 2026))
    end
  end

  describe "PATCH mark_paid" do
    let(:fee) do
      MembershipFee.create!(person: caat, group: groupe_local, year: 2026,
        branche: "jiwu", amount_cents: 5_000_00, currency: "XOF", status: "pending")
    end

    it "marks the fee as paid" do
      sign_in(tresorier)
      patch :mark_paid, params: {group_id: groupe_local.id, id: fee.id,
        membership_fee: {payment_method: "mobile_money", reference: "MM-1", paid_at: "2026-04-29"}}

      expect(fee.reload).to be_paid
      expect(fee.payment_method).to eq("mobile_money")
      expect(fee.reference).to eq("MM-1")
    end
  end

  describe "PATCH mark_exempted" do
    let(:fee) do
      MembershipFee.create!(person: caat, group: groupe_local, year: 2026,
        branche: "jiwu", amount_cents: 5_000_00, currency: "XOF", status: "pending")
    end

    it "marks the fee as exempted" do
      sign_in(tresorier)
      patch :mark_exempted, params: {group_id: groupe_local.id, id: fee.id,
        membership_fee: {comment: "boursier"}}

      expect(fee.reload.status).to eq("exempted")
    end
  end

  describe "POST remind" do
    it "enqueues reminder mailer for pending fees with email" do
      caat.update!(email: "caat@example.test")
      MembershipFee.create!(person: caat, group: groupe_local, year: 2026,
        branche: "jiwu", amount_cents: 5_000_00, currency: "XOF", status: "pending")
      sign_in(tresorier)

      expect {
        post :remind, params: {group_id: groupe_local.id, year: 2026}
      }.to have_enqueued_mail(MembershipFeeMailer, :unpaid_reminder).at_least(1)
    end
  end
end
