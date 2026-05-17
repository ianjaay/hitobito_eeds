# frozen_string_literal: true

module Eeds::ProgressionsHelper
  BRANCHE_LABELS = {
    "mbootaay" => "Mbootaay",
    "kayon"    => "Kayon",
    "dental"   => "Dental",
    "galle"    => "Gàlle"
  }.freeze

  DOMAINE_LABELS = {
    "enab_physique"     => "Enabilité physique",
    "enab_intellectuel" => "Enabilité intellectuelle",
    "donn_social"       => "Donnerie / Njaak social",
    "yees_spirituel"    => "Yeesal / Spiritualité",
    "enab_affectif"     => "Enabilité affective",
    "communication"     => "Communication",
    "environnement"     => "Environnement",
    "gestion"           => "Gestion",
    "sante"             => "Santé",
    "citoyennete"       => "Citoyenneté",
    "technologie"       => "Technologie",
    "arts_culture"      => "Arts & Culture",
    "leadership"        => "Leadership"
  }.freeze

  STATUS_CLASSES = {
    "not_started" => "bg-secondary",
    "in_progress" => "bg-primary",
    "needs_work"  => "bg-warning text-dark",
    "validated"   => "bg-success"
  }.freeze

  MENMEN_ICONS = {
    "men_communicateur" => "📡", "men_environnementaliste" => "🌿",
    "men_gestionnaire" => "📊", "men_secouriste" => "🏥",
    "men_citoyen" => "🏛️", "men_technologue" => "⚙️",
    "men_artiste" => "🎨", "men_leader" => "🌟"
  }.freeze

  def branche_label(branche)
    BRANCHE_LABELS[branche.to_s] || branche.to_s.humanize
  end

  def domaine_label(domaine)
    DOMAINE_LABELS[domaine.to_s] || domaine.to_s.humanize
  end

  def progression_status_badge(progression)
    css = STATUS_CLASSES[progression.status] || "bg-secondary"
    label = t("eeds.progressions.statuses.#{progression.status}", default: progression.status.humanize)
    content_tag(:span, label, class: "badge #{css}")
  end

  # Renders a circular SVG progress indicator
  def render_circular_progress(pct, size = 76, color = '#FCD116')
    r = (size - 8) / 2
    c = 2 * Math::PI * r
    offset = c * (1 - pct / 100.0)
    content_tag(:svg, width: size, height: size, viewBox: "0 0 #{size} #{size}") do
      bg_circle = content_tag(:circle, nil, cx: size / 2, cy: size / 2, r: r,
        fill: "none", stroke: "rgba(255,255,255,0.15)", "stroke-width": 6)
      fg_circle = content_tag(:circle, nil, cx: size / 2, cy: size / 2, r: r,
        fill: "none", stroke: color, "stroke-width": 6,
        "stroke-dasharray": c.round(1), "stroke-dashoffset": offset.round(1),
        "stroke-linecap": "round",
        transform: "rotate(-90 #{size / 2} #{size / 2})",
        style: "transition: stroke-dashoffset 1s cubic-bezier(.4,0,.2,1);")
      label = content_tag(:text, "#{pct}%", x: "50%", y: "50%",
        "text-anchor": "middle", dy: ".35em",
        fill: "#fff", "font-size": (size * 0.22).round, "font-weight": 800)
      bg_circle + fg_circle + label
    end
  end

  # Renders a badge image or falls back to emoji icon
  def badge_icon_for(qualification_kind, size: 48)
    if qualification_kind.badge_image.attached?
      image_tag url_for(qualification_kind.badge_image.variant(:thumb)),
                style: "width: #{size}px; height: #{size}px; border-radius: 50%; object-fit: cover;",
                alt: qualification_kind.label
    else
      fallback = if qualification_kind.category == "menmen"
                   MENMEN_ICONS[qualification_kind.key] || "🏅"
                 else
                   "⚜️"
                 end
      content_tag(:span, fallback, style: "font-size: #{(size * 0.6).round}px; line-height: #{size}px;")
    end
  end

  def badge_image_for(qualification_kind, size: 72)
    if qualification_kind.badge_image.attached?
      image_tag url_for(qualification_kind.badge_image.variant(:medium)),
                style: "width: #{size}px; height: #{size}px; border-radius: 50%; object-fit: cover; border: 2px solid rgba(255,255,255,0.3);",
                alt: qualification_kind.label
    else
      nil
    end
  end
end
