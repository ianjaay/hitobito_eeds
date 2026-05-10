# frozen_string_literal: true

# EEDS — Branches de progression scoute.
# 4 niveaux franchis successivement par les jeunes au sein d'une unité :
#   Jiwu wi   (jaune)
#   Lawtan wi (vert)
#   Toor-Toor wi (blanc)
#   Mennef mi (rouge)
#
# Modélisées comme QualificationKind pour bénéficier gratuitement de :
#   - l'attribution datée (start_at / qualified_at) à une Personne
#   - l'historique de progression
#   - l'export, la recherche, l'API
#
# Idempotent (utilise QualificationKind.seed sur :id).
# IDs réservés EEDS : 1001-1099.

EEDS_BRANCHES = [
  {id: 1001, key: :jiwu,      label_fr: "Jiwu wi",      color: "Jaune"},
  {id: 1002, key: :lawtan,    label_fr: "Lawtan wi",    color: "Vert"},
  {id: 1003, key: :toor_toor, label_fr: "Toor-Toor wi", color: "Blanc"},
  {id: 1004, key: :mennef,    label_fr: "Mennef mi",    color: "Rouge"}
].freeze

quali_kinds = QualificationKind.seed(:id,
  *EEDS_BRANCHES.map { |b| {id: b[:id], validity: nil, reactivateable: nil} }
)

QualificationKind::Translation.seed(:qualification_kind_id, :locale,
  *EEDS_BRANCHES.flat_map do |b|
    [
      {qualification_kind_id: b[:id], locale: "fr",
       label: "#{b[:label_fr]} (#{b[:color]})",
       description: "Branche de progression EEDS — niveau #{b[:label_fr]} (#{b[:color].downcase})."},
      {qualification_kind_id: b[:id], locale: "de",
       label: b[:label_fr]},
      {qualification_kind_id: b[:id], locale: "en",
       label: b[:label_fr]},
      {qualification_kind_id: b[:id], locale: "it",
       label: b[:label_fr]}
    ]
  end
)

puts "→ EEDS branches de progression : #{quali_kinds.size} QualificationKind seeded."
