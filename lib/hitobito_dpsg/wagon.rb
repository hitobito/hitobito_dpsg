# frozen_string_literal: true

#  Copyright (c) 2012-2026, Deutsche Pfadfinder*innenschaft Sankt Georg. This file is part of
#  hitobito_dpsg and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dpsg.

module HitobitoDpsg
  class Wagon < Rails::Engine
    include Wagons::Wagon

    # Set the required application version.
    app_requirement ">= 0"

    # Add a load path for this specific wagon
    config.autoload_paths += %W[
      #{config.root}/app/abilities
      #{config.root}/app/domain
      #{config.root}/app/jobs
    ]

    config.to_prepare do # rubocop:disable Metrics/BlockLength
      # extend application classes here
      # Group.include Dpsg::Group

      %i[Bezirk Bund Land Stamm].each do |prefix|
        ::Group.const_get("#{prefix}Arbeitsbereiche").children(
          ::Group.const_get("#{prefix}Biber"),
          ::Group.const_get("#{prefix}Jungpfadfinderstufe")
        )

        ::Group.const_get("#{prefix}Stufen").children(
          ::Group.const_get("#{prefix}Biber"),
          ::Group.const_get("#{prefix}Jungpfadfinderstufe")
        )
      end

      ::Group::Gruppen.children ::Group::StammGruppeBiber, ::Group::StammGruppeJungpfadfinder

      Group::Stamm.used_attributes += [:eingeschraenkt]
      [Group::Bundesebene, Group::Landesverband, Group::Bezirk, Group::Stamm].each do |layer_group|
        layer_group.used_attributes += [:strukturnummer]
      end

      # Eine Person kann zu jedem Zeitpunkt nur eine Ordentliche- oder Fördermitgliedschaft haben.
      [Group::Mitglieder::OrdentlicheMitgliedschaft,
        Group::Mitglieder::Foerdermitgliedschaft].each do |membership_role|
        membership_role.mutually_exclusive_in :membership_global, scope: :global
      end

      # Eine Person kann in jedem Stamm zu jedem Zeitpunkt nur eine Mitgliedschaft haben. Eine
      # Zweitmitgliedschaft ist nur erlaubt in einem Stamm in dem nicht bereits eine
      # andere Mitgliedschaft vorhanden ist.
      [Group::Mitglieder::OrdentlicheMitgliedschaft,
        Group::Mitglieder::Foerdermitgliedschaft,
        Group::Mitglieder::Zweitmitgliedschaft].each do |membership_role|
        membership_role.mutually_exclusive_in :membership_stamm, scope: :layer
      end

      # Eine Mitgliedschaft im Stamm ist Voraussetzung für bestimmte Rollen im selben Stamm. Endet
      # die Mitgliedschaft, werden die abhängigen Rollen gekürzt.
      [Group::Mitglieder::OrdentlicheMitgliedschaft,
        Group::Mitglieder::Foerdermitgliedschaft,
        Group::Mitglieder::Zweitmitgliedschaft].each do |membership_role|
        membership_role.provides_role :stamm_mitgliedschaft
      end
      Group::StammGruppePfadfinder::Mitglied
        .depends_on_role :stamm_mitgliedschaft, scope: :layer, on_uncovered: :cascade

      # Eine Zweitmitgliedschaft setzt eine Ordentliche- oder Fördermitgliedschaft voraus.
      [Group::Mitglieder::OrdentlicheMitgliedschaft,
        Group::Mitglieder::Foerdermitgliedschaft].each do |membership_role|
        membership_role.provides_role :dpsg_mitgliedschaft
      end
      Group::Mitglieder::Zweitmitgliedschaft
        .depends_on_role :dpsg_mitgliedschaft, scope: :global, on_uncovered: :cascade
    end

    initializer "dpsg.add_settings" do |_app|
      Settings.add_source!(File.join(paths["config"].existent, "settings.yml"))
      Settings.reload!
    end

    initializer "dpsg.add_inflections" do |_app|
      ActiveSupport::Inflector.inflections do |inflect|
        # inflect.irregular "census", "censuses"
      end
    end

    private

    def seed_fixtures
      fixtures = root.join("db", "seeds")
      ENV["NO_ENV"] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)] # rubocop:disable Rails/EnvironmentVariableAccess -- This is initialization
    end
  end
end
