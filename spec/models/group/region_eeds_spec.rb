# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Group::RegionEeds do
  subject(:type) { described_class }

  it "is a layer" do
    expect(type.layer).to be true
  end

  it "accepts District as direct child" do
    expect(type.possible_children).to eq([Group::District])
  end

  it "declares the expected role types" do
    expect(type.role_types).to match_array([
      Group::RegionEeds::CommissaireRegional,
      Group::RegionEeds::CommissaireRegionalAdjointJiwu,
      Group::RegionEeds::CommissaireRegionalAdjointLawtan,
      Group::RegionEeds::CommissaireRegionalAdjointToorToor,
      Group::RegionEeds::CommissaireRegionalAdjointMenneef,
      Group::RegionEeds::CommissaireRegionalAdjointFormation,
      Group::RegionEeds::CommissaireRegionalAdjointCommunication,
      Group::RegionEeds::CommissaireRegionalAdjointProgramme,
      Group::RegionEeds::MembreEquipeRegionale,
      Group::RegionEeds::SecretaireRegional,
      Group::RegionEeds::TresorierRegional
    ])
  end

  it "enforces 2FA on the Commissaire régional role" do
    expect(Group::RegionEeds::CommissaireRegional.two_factor_authentication_enforced).to be true
  end
end
