# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Détecte si une personne (existante ou nouveaux attributs) correspond à
# une entrée de la `Blacklist`. Match basé sur :
#   - couple (first_name, last_name) exact (case-insensitive)
#   - matricule_scout exact
#   - email exact (case-insensitive)
#   - téléphone (9 derniers chiffres uniquement)
class Eeds::BlacklistDetector
  attr_reader :person

  def initialize(person, attributes = nil)
    @person = attributes.present? ? Person.new(attributes) : person
  end

  def matches?
    matching_records.any?
  end

  def matching_records
    @matching_records ||= name_or_email_or_matricule_matches | phone_matches
  end

  private

  def name_or_email_or_matricule_matches
    bl = Blacklist.arel_table
    conditions = []
    conditions << bl[:first_name].lower.eq(person.first_name.to_s.downcase)
      .and(bl[:last_name].lower.eq(person.last_name.to_s.downcase)) if person.first_name.present? && person.last_name.present?
    conditions << bl[:email].lower.eq(person.email.to_s.downcase)   if person.email.present?
    conditions << bl[:matricule_scout].eq(person.try(:matricule_scout)) if person.try(:matricule_scout).present?
    return [] if conditions.empty?

    Blacklist.where(conditions.inject(:or)).to_a
  end

  def phone_matches
    person_numbers = strip_numbers(person_phone_numbers)
    return [] if person_numbers.empty?

    bl_numbers = Blacklist.where.not(phone_number: [nil, ""]).pluck(:id, :phone_number)
    matched_ids = bl_numbers.select { |_id, n| person_numbers.include?(strip_one(n)) }.map(&:first)
    Blacklist.where(id: matched_ids).to_a
  end

  def person_phone_numbers
    return person.phone_numbers.pluck(:number) if person.respond_to?(:phone_numbers) && person.persisted?
    return [person.try(:parent_contact_phone)].compact if person.try(:parent_contact_phone)

    []
  end

  def strip_numbers(arr)
    arr.map { |n| strip_one(n) }.compact
  end

  def strip_one(n)
    return nil if n.blank?

    n.gsub(/\D/, "").match(/\d{9}\z/).to_s.presence
  end
end
