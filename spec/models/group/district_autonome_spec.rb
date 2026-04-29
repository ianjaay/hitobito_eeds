# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Group::DistrictAutonome do
  subject(:type) { described_class }

  it "is a layer" do
    expect(type.layer).to be true
  end

  it "is a possible child of Group::National" do
    expect(Group::National.possible_children).to include(type)
  end

  it "accepts Group::GroupeLocal as direct children" do
    expect(type.possible_children).to eq([Group::GroupeLocal])
  end

  it "declares the same role types as Group::District" do
    expect(type.role_types.map { |r| r.name.demodulize }).to match_array(
      Group::District.role_types.map { |r| r.name.demodulize }
    )
  end

  it "enforces 2FA on the Commissaire de district" do
    expect(type::CommissaireDistrict.two_factor_authentication_enforced).to be true
  end
end
