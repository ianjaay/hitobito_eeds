# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

module Eeds::Sheet::Group
  extend ActiveSupport::Concern

  included do
    tabs.insert(4,
      Sheet::Tab.new("activerecord.models.event/camp.other",
        :camp_group_events_path,
        params: {returning: true},
        if: lambda do |view, group|
          group.event_types.include?(::Event::Camp) &&
            view.can?(:"index_event/camps", group)
        end))

    tabs << Sheet::Tab.new("eeds.tabs.membership_fees",
      :group_membership_fees_path,
      if: lambda do |view, group|
        view.can?(:show, ::MembershipFee.new(group: group))
      end)

    tabs << Sheet::Tab.new("eeds.tabs.member_counts",
      :group_member_counts_path,
      if: lambda do |view, group|
        view.can?(:show, ::MemberCount.new(group: group))
      end)

    tabs << Sheet::Tab.new("eeds.tabs.crises",
      :group_crises_path,
      if: lambda do |view, group|
        view.can?(:show, ::Crisis.new(group: group))
      end)
  end
end
