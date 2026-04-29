# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

require "csv"

# Importeur CSV de membres EEDS.
#
# Deux modes d'utilisation :
#   - `dry_run` (par défaut) : analyse le fichier sans rien persister, retourne
#     un Result indiquant les lignes valides (à créer / mettre à jour) et les
#     erreurs.
#   - `commit` : exécute l'import dans une transaction unique. En cas d'erreur
#     bloquante (validation, groupe introuvable, etc.) la transaction est
#     intégralement annulée.
#
# Stratégie de matching d'un Person existant :
#   1. Lookup par `matricule_scout` (case-insensitive) si présent
#   2. Sinon lookup par `email` (si présent)
#   3. Sinon création d'une nouvelle Person
#
# Colonnes attendues (en-tête CSV, ordre indifférent) :
#   matricule_scout, last_name, first_name, gender, birthday, branche,
#   group_id, email, parent_contact_name, parent_contact_phone,
#   parent_contact_email
#
# Le Role créé pour la nouvelle affectation est le `standard_role` du groupe
# cible (Caat / Arunga / Jambaar / Mawdo selon la branche).
class Eeds::MemberCsvImporter
  REQUIRED_HEADERS = %w[
    matricule_scout last_name first_name branche group_id
  ].freeze

  OPTIONAL_HEADERS = %w[
    gender birthday email
    parent_contact_name parent_contact_phone parent_contact_email
  ].freeze

  ALL_HEADERS = (REQUIRED_HEADERS + OPTIONAL_HEADERS).freeze

  Result = Struct.new(:created, :updated, :errors, keyword_init: true) do
    def initialize(*)
      super
      self.created ||= []
      self.updated ||= []
      self.errors  ||= []
    end

    def success? = errors.empty?
    def total = created.size + updated.size
  end

  RowError = Struct.new(:line, :matricule, :messages, keyword_init: true)

  attr_reader :result

  # @param csv_io [IO, String] fichier CSV (IO ou contenu)
  def initialize(csv_io)
    @csv_io = csv_io
    @result = Result.new
  end

  def dry_run
    process(persist: false)
    result
  end

  def commit
    Person.transaction do
      process(persist: true)
      raise ActiveRecord::Rollback unless result.success?
    end
    result
  end

  private

  def process(persist:)
    rows = parse_csv
    return unless rows # parse error already recorded

    rows.each_with_index do |row, idx|
      line = idx + 2 # +1 for header, +1 for 1-based numbering
      process_row(row, line: line, persist: persist)
    end
  end

  def parse_csv
    raw = @csv_io.respond_to?(:read) ? @csv_io.read : @csv_io.to_s
    table = CSV.parse(raw, headers: true, header_converters: ->(h) { h.to_s.strip.downcase })

    missing = REQUIRED_HEADERS - table.headers.compact
    if missing.any?
      result.errors << RowError.new(
        line: 1, matricule: nil,
        messages: ["En-têtes obligatoires manquants : #{missing.join(", ")}"]
      )
      return nil
    end

    table
  rescue CSV::MalformedCSVError => e
    result.errors << RowError.new(line: 0, matricule: nil, messages: ["CSV invalide : #{e.message}"])
    nil
  end

  def process_row(row, line:, persist:)
    attrs = row.to_h.transform_values { |v| v.is_a?(String) ? v.strip.presence : v }
    matricule = attrs["matricule_scout"]

    group = lookup_group(attrs["group_id"])
    unless group
      record_error(line, matricule, ["Groupe introuvable (group_id=#{attrs["group_id"]})"])
      return
    end

    person = lookup_person(attrs)
    is_new = person.nil?
    person ||= Person.new

    assign_person_attrs(person, attrs)

    unless person.valid?
      record_error(line, matricule, person.errors.full_messages)
      return
    end

    role_class = group.class.standard_role
    unless role_class
      record_error(line, matricule, ["Le groupe #{group.to_s} n'a pas de rôle standard"])
      return
    end

    if persist
      person.save!
      ensure_role(person, group, role_class)
    end

    if is_new
      result.created << summary_for(person, group, line)
    else
      result.updated << summary_for(person, group, line)
    end
  end

  def lookup_group(group_id)
    return nil if group_id.blank?
    Group.find_by(id: group_id)
  end

  def lookup_person(attrs)
    if attrs["matricule_scout"].present?
      found = Person.where("LOWER(matricule_scout) = ?", attrs["matricule_scout"].downcase).first
      return found if found
    end
    if attrs["email"].present?
      Person.find_by(email: attrs["email"])
    end
  end

  def assign_person_attrs(person, attrs)
    %w[matricule_scout last_name first_name gender email branche unite
       parent_contact_name parent_contact_phone parent_contact_email
       profession competences].each do |k|
      person[k] = attrs[k] if attrs.key?(k)
    end
    person.birthday = parse_date(attrs["birthday"]) if attrs["birthday"].present?
  end

  def parse_date(value)
    Date.parse(value)
  rescue ArgumentError, TypeError
    nil
  end

  def ensure_role(person, group, role_class)
    return if person.roles.where(group_id: group.id, type: role_class.sti_name).exists?
    Role.create!(person: person, group: group, type: role_class.sti_name)
  end

  def summary_for(person, group, line)
    {
      line: line,
      matricule: person.matricule_scout,
      name: "#{person.first_name} #{person.last_name}".strip,
      group: group.to_s,
      branche: person.branche
    }
  end

  def record_error(line, matricule, messages)
    result.errors << RowError.new(line: line, matricule: matricule, messages: messages)
  end
end
