# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

# Specs partagées pour les 4 branches pédagogiques EEDS. Chacune possède
# Njiit (chef d'unité), Reefaan (adjoint), un rôle « chef de sous-unité »
# (sizaine / patrouille / équipe) et un rôle membre standard spécifique.
RSpec.shared_examples "an EEDS branch" do |group_class, member_role_name, sub_unit_role_name|
  let(:branch) { group_class }
  let(:member_role) { branch.const_get(member_role_name) }
  let(:sub_unit_role) { branch.const_get(sub_unit_role_name) }

  it "is not a layer (lives inside a Groupe Local)" do
    expect(branch.layer).to be_falsey
  end

  it "declares Njiit, Reefaan, the sub-unit chef and the standard member role" do
    role_names = branch.role_types.map { |r| r.name.demodulize.to_sym }
    expect(role_names).to match_array([:Njiit, :Reefaan, sub_unit_role_name, member_role_name])
  end

  it "uses the branch-specific member role as the standard role" do
    expect(branch.standard_role).to eq(member_role)
  end

  it "hides member-level roles from upper layers" do
    expect(member_role.visible_from_above).to be(false)
  end

  it "grants :group_full to Njiit (chef d'unité)" do
    expect(branch.const_get(:Njiit).permissions).to include(:group_full)
  end

  it "grants :group_read to the sub-unit chef" do
    expect(sub_unit_role.permissions).to include(:group_read)
  end

  it "exposes the official branch color" do
    expect(branch.branch_color).to match(/\A#[0-9a-fA-F]{6}\z/)
    expect(branch.branch_color_name).to be_a(String)
  end
end

describe Group::Mbootaay do
  it_behaves_like "an EEDS branch", Group::Mbootaay, :Caat, :ChefSizaine
end

describe Group::Kayon do
  it_behaves_like "an EEDS branch", Group::Kayon, :Arunga, :ChefPatrouille
end

describe Group::Nawka do
  it_behaves_like "an EEDS branch", Group::Nawka, :Jambaar, :ChefEquipe
end

describe Group::Galle do
  it_behaves_like "an EEDS branch", Group::Galle, :Mawdo, :ChefEquipe
end
