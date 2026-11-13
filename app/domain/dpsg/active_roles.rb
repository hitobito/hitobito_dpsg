# frozen_string_literal: true

#  Copyright (c) 2026, Deutsche Pfadfinder*innenschaft Sankt Georg. This file is part of
#  hitobito_dpsg and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dpsg

# Rollentypen, die gemäss Satzung eine aktive Mitgliedschaft voraussetzen: Wer ein Leitungsamt
# übernimmt oder mitarbeitet, wird damit Mitglied.
module Dpsg::ActiveRoles
  class << self
    # Aktive Rollen im Stamm. Sie setzen eine aktive Mitgliedschaft im selben Stamm voraus.
    def in_stamm
      [
        *Group::Gruppen.possible_children.flat_map(&:role_types),
        Group::Stamm::Stammesmitgliederverwaltung,
        Group::Stamm::AnsprechpersonHeimvermietung,
        Group::Stamm::Heimwartung,
        Group::Stamm::Landesdelegiert,
        Group::Stamm::Bezirksdelegiert,
        *ak_mitarbeiter(Group::StammArbeitsbereiche)
      ]
    end

    # Aktive Rollen auf Bezirks-, Diözesan- und Bundesebene. Sie setzen eine beliebige aktive
    # Mitgliedschaft voraus.
    def above_stamm
      [
        Group::Landesvorstand::Landesvorsitz,
        Group::Bundesvorstand::Bundesvorsitz,
        Group::Landesverband::Landesmitarbeiter,
        Group::Bundesebene::Bundesmitarbeiter,
        Group::Landesverband::Bundesdelegiert,
        Group::BezirkInternationales::Beauftragt,
        Group::LandInternationales::Beauftragt,
        Group::BundInternationales::Beauftragt,
        *ak_mitarbeiter(Group::BezirkArbeitsbereiche, Group::LandArbeitsbereiche,
          Group::BundArbeitsbereiche),
        *projekt_roles
      ]
    end

    private

    def projekt_roles
      [
        Group::Projekt::Lagerleitung,
        Group::Projekt::Mitarbeiter,
        Group::Projekt::Beauftragt,
        Group::Bereich::Bereichsleitung,
        Group::Bereich::Mitarbeiter
      ]
    end

    def ak_mitarbeiter(*arbeitsbereiche)
      arbeitsbereiche.flat_map { |group_type| group_types_below(group_type) }.uniq
        .flat_map(&:role_types)
        .select { |role_type| role_type.name.demodulize == "AKMitarbeiter" }
    end

    def group_types_below(group_type)
      group_type.possible_children.flat_map { |child| [child, *group_types_below(child)] }
    end
  end
end
