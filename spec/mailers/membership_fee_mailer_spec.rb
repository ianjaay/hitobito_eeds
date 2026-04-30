# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe MembershipFeeMailer do
  let(:national)     { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS") }
  let(:groupe_local) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GL M", parent: national) }
  let(:person)       { Fabricate(:person, email: "membre@example.test") }

  let(:fee) do
    MembershipFee.create!(person: person, group: groupe_local, year: 2026,
      branche: "jiwu", amount_cents: 5_000_00, currency: "XOF", status: "pending")
  end

  before do
    CustomContent.find_or_create_by!(key: described_class::CONTENT_UNPAID_REMINDER) do |c|
      c.label = "Rappel cotisation"
      c.subject = "Rappel cotisation {year}"
      c.body = "Bonjour {recipient-name}, votre cotisation {year} ({branche}) de {amount} pour {group-name} est due."
      c.placeholders_required = "recipient-name, year, branche, amount, group-name"
    end
  end

  it "sends to the person's email with placeholders interpolated" do
    mail = described_class.unpaid_reminder(fee)
    expect(mail.to).to eq(["membre@example.test"])
    expect(mail.subject).to include("2026")
    body = mail.body.to_s
    expect(body).to include(person.to_s)
    expect(body).to include("2026")
    expect(body).to include("XOF")
  end

  it "returns nil when person has no email" do
    person.update!(email: nil)
    mail = described_class.unpaid_reminder(fee)
    expect(mail.message).to be_a(ActionMailer::Base::NullMail)
  end
end
