# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "spec_helper"

describe Census do
  it "defaults year and start_at on initialization" do
    today = Time.zone.today
    c = described_class.new
    expect(c.start_at).to eq(today)
    expect(c.year).to eq(today.year)
  end

  it "is invalid when start_at is nil after explicit reset" do
    c = described_class.new
    c.start_at = nil
    c.year = nil
    expect(c).not_to be_valid
    expect(c.errors[:start_at]).to be_present
    expect(c.errors[:year]).to be_present
  end

  it "enforces unique year" do
    described_class.create!(year: 2026, start_at: Date.new(2026, 1, 1))
    dup = described_class.new(year: 2026, start_at: Date.new(2026, 6, 1))
    expect(dup).not_to be_valid
    expect(dup.errors[:year]).to be_present
  end

  it "rejects finish_at before start_at" do
    c = described_class.new(year: 2026,
      start_at: Date.new(2026, 6, 1), finish_at: Date.new(2026, 1, 1))
    expect(c).not_to be_valid
    expect(c.errors[:finish_at]).to be_present
  end

  it "considers itself open between start_at and finish_at" do
    c = described_class.new(year: 2026,
      start_at: Date.new(2026, 1, 1), finish_at: Date.new(2026, 12, 31))
    expect(c.open?(Date.new(2026, 6, 1))).to be true
    expect(c.open?(Date.new(2027, 1, 1))).to be false
    expect(c.open?(Date.new(2025, 12, 31))).to be false
  end

  it "current returns the most recent census whose start_at is in the past" do
    described_class.create!(year: 2025, start_at: Date.new(2025, 1, 1))
    cur = described_class.create!(year: 2026, start_at: Date.new(2026, 1, 1))
    described_class.create!(year: 2099, start_at: Date.new(2099, 1, 1))
    expect(described_class.current).to eq(cur)
  end
end
