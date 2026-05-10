# frozen_string_literal: true

#  EEDS — Sous-groupe (équipe / patrouille / sizaine) au sein d'une unité
#  (Mbotaay, Kayon, Ñawka, Gàlle).
#
#  Les sous-groupes ne forment pas une couche (`layer = false`) :
#  les permissions sont héritées de l'unité parente.
#  L'ajout d'un membre dans un sous-groupe utilise le formulaire
#  d'attribution de rôle standard de hitobito.

class Group::Subgroup < Group
  self.layer = false

  children # aucun enfant : un sous-groupe est terminal

  ### ROLES

  class Leader < ::Role
    self.permissions = [:group_read]
    self.kind = :member
  end

  class Member < ::Role
    self.permissions = [:group_read]
    self.kind = :member
  end

  roles Leader, Member

  self.standard_role = Member
end
