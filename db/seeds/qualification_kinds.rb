# frozen_string_literal: true

# Seed EEDS : peuple les QualificationKinds (JEEGO + MËN-MËN)
# et les critères de validation des brevets MËN-MËN.
#
# Idempotent (utilise SeedFu .seed).
# IDs réservés EEDS : 2001–2068
#   2001–2060 : JEEGO (4 branches × 5 domaines × 3 niveaux)
#   2061–2068 : MËN-MËN (8 brevets)

catalog_path = File.join(HitobitoEeds::Wagon.root, "config", "qualification_kinds.yml")
catalog = YAML.load_file(catalog_path)

# Clés de référence (pas des QualificationKinds)
META_KEYS = %w[branches domaines].freeze

# Attribuer des IDs stables à chaque clé
id_counter = 2001
entries = []

catalog.each do |key, data|
  next if META_KEYS.include?(key)
  next unless data.is_a?(Hash) && data["category"].present?

  entries << {id: id_counter, key: key, label: data["label"],
              category: data["category"], metadata: data["metadata"] || {}}
  id_counter += 1
end

# 1) Seed les QualificationKinds
QualificationKind.seed(:id,
  *entries.map do |e|
    {id: e[:id], key: e[:key], category: e[:category],
     metadata: e[:metadata], validity: nil, reactivateable: nil}
  end
)

# 2) Seed les traductions (fr, de, en, it)
QualificationKind::Translation.seed(:qualification_kind_id, :locale,
  *entries.flat_map do |e|
    %w[fr de en it].map do |locale|
      {qualification_kind_id: e[:id], locale: locale, label: e[:label]}
    end
  end
)

puts "→ EEDS Progression : #{entries.size} QualificationKinds seeded (JEEGO + MËN-MËN)"

# ────────────────────────────────────────────────────────────
# Critères MËN-MËN
# ────────────────────────────────────────────────────────────

MENMEN_CRITERIA = {
  "men_communicateur" => [
    "Réaliser une animation radio ou podcast de 15 min",
    "Rédiger un article ou rapport de 500 mots",
    "Animer une séance de débat devant l'unité",
    "Produire un support visuel (affiche, présentation)"
  ],
  "men_environnementaliste" => [
    "Organiser une action de reboisement (min. 10 arbres)",
    "Réaliser un exposé sur un enjeu environnemental local",
    "Mettre en place un système de tri des déchets dans l'unité",
    "Participer à une journée de nettoyage communautaire"
  ],
  "men_gestionnaire" => [
    "Établir le budget d'une activité et le respecter",
    "Planifier et organiser un événement de bout en bout",
    "Tenir la comptabilité de l'unité pendant 3 mois",
    "Réaliser un bilan écrit d'un projet mené"
  ],
  "men_secouriste" => [
    "Maîtriser les gestes de premiers secours (PLS, RCP)",
    "Obtenir le PSC1 ou équivalent local",
    "Organiser un exercice d'évacuation pour l'unité",
    "Constituer et gérer une trousse de secours",
    "Former les plus jeunes aux gestes de base"
  ],
  "men_citoyen" => [
    "Réaliser un projet de service communautaire",
    "Participer à une action citoyenne (vote, sensibilisation)",
    "Organiser un débat sur un sujet de société",
    "Représenter l'unité lors d'un événement public"
  ],
  "men_technologue" => [
    "Créer un outil numérique utile à l'unité (site, app, tableur)",
    "Animer un atelier d'initiation informatique",
    "Résoudre un problème technique pour la communauté",
    "Documenter un projet technique de bout en bout"
  ],
  "men_artiste" => [
    "Réaliser une œuvre artistique (peinture, sculpture, photo)",
    "Organiser un spectacle ou une représentation pour l'unité",
    "Transmettre un savoir-faire culturel aux plus jeunes",
    "Participer à la valorisation du patrimoine local"
  ],
  "men_leader" => [
    "Diriger une patrouille pendant un camp complet",
    "Organiser une activité de A à Z (planification → bilan)",
    "Encadrer un groupe de plus jeunes pendant 3 séances",
    "Résoudre un conflit au sein de l'unité (médiation documentée)",
    "Représenter l'unité lors d'un événement externe"
  ]
}.freeze

criteria_created = 0

MENMEN_CRITERIA.each do |men_key, labels|
  qk = QualificationKind.find_by(key: men_key)
  unless qk
    puts "  ⚠ QualificationKind #{men_key} introuvable, critères ignorés"
    next
  end

  labels.each_with_index do |label, idx|
    existing = Eeds::Criterion.find_by(qualification_kind_id: qk.id, position: idx + 1)
    unless existing
      Eeds::Criterion.create!(
        qualification_kind_id: qk.id,
        position: idx + 1,
        label: label
      )
      criteria_created += 1
    end
  end
end

puts "→ Critères MËN-MËN : #{criteria_created} créés"
