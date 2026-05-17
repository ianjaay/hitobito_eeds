# frozen_string_literal: true

# Calcule la répartition financière d'un paiement entre les niveaux hiérarchiques.
# Règle par défaut : Local 20%, District 15%, Région 15%, National 50%
module Maas
  class DistributionService
    # Pourcentages par défaut — modifiables via constante ou config
    DEFAULT_RULES = {
      "local"    => 20,
      "district" => 15,
      "region"   => 15,
      "national" => 50
    }.freeze

    def initialize(transaction:, rules: DEFAULT_RULES)
      @transaction = transaction
      @rules = rules
    end

    def distribute!
      subscription = @transaction.membership_subscription
      group = subscription.group

      hierarchy = resolve_hierarchy(group)

      @rules.each do |level, pct|
        structure_id = hierarchy[level]
        next unless structure_id

        montant = (@transaction.montant * pct / 100.0).round(2)

        Maas::FinancialDistribution.create!(
          payment_transaction: @transaction,
          structure_type: level,
          structure_id: structure_id,
          pourcentage: pct,
          montant: montant
        )

        # Créditer le wallet
        wallet = Maas::StructureWallet.find_or_create_for(structure_id, level)
        wallet.credit!(montant)
      end
    end

    private

    # Résout la hiérarchie du groupe vers les niveaux supérieurs
    # en utilisant la structure de groupes Hitobito.
    def resolve_hierarchy(group)
      hierarchy = { "local" => group.id }

      # Remonter dans la hiérarchie des groupes
      current = group
      levels = %w[district region national]
      level_idx = 0

      while current.parent_id && level_idx < levels.size
        current = ::Group.find_by(id: current.parent_id)
        break unless current

        hierarchy[levels[level_idx]] = current.id
        level_idx += 1
      end

      # Le national est toujours le groupe racine (Root)
      root = ::Group.find_by(type: "Group::Root")
      hierarchy["national"] = root.id if root

      hierarchy
    end
  end
end
