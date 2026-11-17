# frozen_string_literal: true

#  Copyright (c) 2026, Deutsche Pfadfinder*innenschaft Sankt Georg. This file is part of
#  hitobito_dpsg and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dpsg

# Rollentypen, die gemäss Satzung eine aktive Mitgliedschaft voraussetzen: Ämter und Mitarbeit
# setzen eine aktive Mitgliedschaft voraus, technische Funktionen, externe Stellen und Gremien
# nicht.
module Dpsg::ActiveRoles
  ARBEITSBEREICH_ROLES = %w[Beauftragt AKLeitung AKMitarbeiter].freeze

  class << self
    # Aktive Rollen im Stamm. Sie setzen eine aktive Mitgliedschaft im selben Stamm voraus.
    def in_stamm
      [
        *Group::Gruppen.possible_children.flat_map(&:role_types),
        *stamm_roles,
        *arbeitsbereich_roles(Group::StammArbeitsbereiche)
      ]
    end

    # Aktive Rollen auf Bezirks-, Diözesan- und Bundesebene. Sie setzen eine beliebige aktive
    # Mitgliedschaft voraus.
    def above_stamm
      [
        *bezirk_roles,
        *dioezese_roles,
        *bund_roles,
        *arbeitsbereich_roles(Group::BezirkArbeitsbereiche, Group::LandArbeitsbereiche,
          Group::BundArbeitsbereiche),
        *projekt_roles
      ]
    end

    private

    def stamm_roles
      role_types(Group::Stamm,
        :Stammesfuehrung, :StammesfuehrungStv, :Stammesschatzmeister, :StammesschatzmeisterStv,
        :Stammeskaemmerer, :Stammesmitgliederverwaltung, :Stammesbeauftragt,
        :Stammesgeschaeftsstelle, :Zuschussbeauftragt, :AnsprechpersonBundeslager,
        :Materialwartung, :AnsprechpersonHeimvermietung, :Heimwartung,
        :Landesdelegiert, :LandesdelegiertErsatz, :Bezirksdelegiert)
    end

    def bezirk_roles
      role_types(Group::Bezirk,
        :Bezirkssprecher, :BezirkssprecherStv, :Bezirksschatzmeister, :BezirksschatzmeisterStv,
        :Bezirksbeauftragt)
    end

    def dioezese_roles
      role_types(Group::Landesvorstand,
        :Landesvorsitz, :LandesvorsitzStv, :Landesschatzmeister, :LandesschatzmeisterStv) +
        role_types(Group::Landesverband,
          :Landesmitarbeiter, :Bundesdelegiert, :BundesdelegiertErsatz,
          # Vorläufig, bis DPSG über die Mitarbeit und die Lagerleitungen auf Diözesanebene
          # entschieden hat.
          :Landesmitgliederverwaltung, :StammeskompassModeration, :Materialwartung,
          :Zuschussbeauftragt, :Landeswahlobmensch,
          :BundeslagerUnterlagerleitung, :BundeslagerUnterlagerbereichsleitung)
    end

    def bund_roles
      role_types(Group::Bundesvorstand,
        :Bundesvorsitz, :BundesvorsitzStv, :Bundesschatzmeister, :BundesschatzmeisterStv) +
        role_types(Group::Bundesebene, :Bundesmitarbeiter)
    end

    def projekt_roles
      role_types(Group::Projekt, :Lagerleitung, :LagerleitungStv, :Mitarbeiter, :Beauftragt) +
        role_types(Group::Bereich, :Bereichsleitung, :Mitarbeiter)
    end

    def arbeitsbereich_roles(*arbeitsbereiche)
      arbeitsbereiche.flat_map { |group_type| group_types_below(group_type) }.uniq
        .flat_map(&:role_types)
        .select { |role_type| ARBEITSBEREICH_ROLES.include?(role_type.name.demodulize) }
    end

    def group_types_below(group_type)
      group_type.possible_children.flat_map { |child| [child, *group_types_below(child)] }
    end

    def role_types(group_type, *names)
      names.map { |name| group_type.const_get(name, false) }
    end
  end
end
