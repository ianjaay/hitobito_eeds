# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Eeds::ApprovalChain do
  let(:national) { Group::National.first || Fabricate(Group::National.sti_name, name: "EEDS Test") }

  context "regular hierarchy (national > region > district > groupe local)" do
    let(:region) { Fabricate(Group::RegionEeds.sti_name, name: "Région Dakar", parent: national) }
    let(:district) { Fabricate(Group::District.sti_name, name: "District Pikine", parent: region) }
    let(:groupe_local) { Fabricate(Group::GroupeLocal.sti_name, name: "GL Test", parent: district) }

    it "returns the full chain from groupe_local to national" do
      expect(described_class.new(groupe_local).layers)
        .to eq(%w[groupe_local district region national])
    end

    it "starts at the cursor's own layer when called from a district" do
      expect(described_class.new(district).layers).to eq(%w[district region national])
    end
  end

  context "Groupe Local Autonome (skips intermediate layers)" do
    let(:gla) { Fabricate(Group::GroupeLocalAutonome.sti_name, name: "GLA Bakel", parent: national) }

    it "skips district and region, going straight from groupe_local to national" do
      expect(described_class.new(gla).layers).to eq(%w[groupe_local national])
    end
  end

  context "District Autonome (skips region)" do
    let(:da) { Fabricate(Group::DistrictAutonome.sti_name, name: "DA Kaolack", parent: national) }

    it "skips region, going straight from district to national" do
      expect(described_class.new(da).layers).to eq(%w[district national])
    end
  end
end
