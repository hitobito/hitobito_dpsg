# frozen_string_literal: true

#  Copyright (c) 2026, Deutsche Pfadfinder*innenschaft Sankt Georg. This file is part of
#  hitobito_dpsg and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dpsg

require "spec_helper"

describe Role do
  describe "exclusive membership roles (hitobito/hitobito_dpsg#26)" do
    let(:person) { people(:member) }
    let(:adler_mitglieder) { groups(:adler_mitglieder) } # layer: adler
    let(:biber_mitglieder) { groups(:biber_mitglieder) } # layer: biber
    let(:ordentliche_in_adler) { roles(:member_ordentliche_mitgliedschaft) }

    def create_ordentliche_in_biber
      Group::Mitglieder::OrdentlicheMitgliedschaft.create!(person: person, group: biber_mitglieder)
    end

    describe "global exclusivity of Ordentliche- and Foerdermitgliedschaft" do
      it "rejects a second OrdentlicheMitgliedschaft in the same Stamm" do
        role = Group::Mitglieder::OrdentlicheMitgliedschaft
          .new(person: person, group: adler_mitglieder)

        expect(role).not_to be_valid
        expect(role.errors[:base].first).to include("Ordentliche")
      end

      it "rejects a second OrdentlicheMitgliedschaft in another Stamm" do
        role = Group::Mitglieder::OrdentlicheMitgliedschaft
          .new(person: person, group: biber_mitglieder)

        expect(role).not_to be_valid
        expect(role.errors[:base].first).to include("Ordentliche")
      end

      it "rejects a Foerdermitgliedschaft in the same Stamm" do
        role = Group::Mitglieder::Foerdermitgliedschaft
          .new(person: person, group: adler_mitglieder)

        expect(role).not_to be_valid
        expect(role.errors[:base].first).to include("Ordentliche")
      end

      it "rejects a Foerdermitgliedschaft in another Stamm" do
        role = Group::Mitglieder::Foerdermitgliedschaft
          .new(person: person, group: biber_mitglieder)

        expect(role).not_to be_valid
      end
    end

    describe "exclusivity within a Stamm" do
      it "rejects a Zweitmitgliedschaft in the same Stamm" do
        role = Group::Mitglieder::Zweitmitgliedschaft
          .new(person: person, group: adler_mitglieder)

        expect(role).not_to be_valid
      end
    end

    describe "allowed combinations" do
      it "accepts a Zweitmitgliedschaft in another Stamm" do
        role = Group::Mitglieder::Zweitmitgliedschaft
          .new(person: person, group: biber_mitglieder)

        expect(role).to be_valid
      end

      it "accepts the same membership for another person" do
        role = Group::Mitglieder::OrdentlicheMitgliedschaft
          .new(person: people(:admin), group: adler_mitglieder)

        expect(role).to be_valid
      end

      it "accepts a membership after the previous one ended" do
        ordentliche_in_adler.update_columns(end_on: 1.month.ago.to_date)
        create_ordentliche_in_biber

        role = Group::Mitglieder::Zweitmitgliedschaft
          .new(person: person, group: adler_mitglieder)

        expect(role).to be_valid
      end
    end

    describe "validate_past: false behaviour" do
      it "accepts a mutation entirely in the past" do
        role = Group::Mitglieder::Zweitmitgliedschaft.new(
          person: person, group: adler_mitglieder,
          start_on: 6.months.ago.to_date, end_on: 4.months.ago.to_date
        )

        expect(role).to be_valid
      end

      it "accepts a backdated start_on overlapping an ended membership" do
        ordentliche_in_adler.update_columns(end_on: Date.yesterday)
        create_ordentliche_in_biber

        role = Group::Mitglieder::Zweitmitgliedschaft.new(
          person: person, group: adler_mitglieder,
          start_on: 2.months.ago.to_date
        )

        expect(role).to be_valid
      end

      it "still rejects an overlap in the current period" do
        role = Group::Mitglieder::Zweitmitgliedschaft.new(
          person: person, group: adler_mitglieder,
          start_on: 6.months.ago.to_date
        )

        expect(role).not_to be_valid
      end
    end
  end

  describe "prerequisite membership roles (hitobito/hitobito_dpsg#27)" do
    let(:member) { people(:member) }
    let(:admin) { people(:admin) }

    def depend_on_active_membership(scope)
      contain_exactly(have_attributes(category: :aktive_mitgliedschaft, scope: scope,
        validate_past: false, on_uncovered: :cascade))
    end

    it "has consistent fixtures" do
      expect(Role.all).to all(be_valid)
    end

    describe "configuration" do
      it "lets an Ordentliche Mitgliedschaft provide an active and a DPSG membership" do
        expect(Group::Mitglieder::OrdentlicheMitgliedschaft.provided_prerequisite_categories)
          .to contain_exactly(:aktive_mitgliedschaft, :dpsg_mitgliedschaft)
      end

      it "lets a Foerdermitgliedschaft provide only a DPSG membership" do
        expect(Group::Mitglieder::Foerdermitgliedschaft.provided_prerequisite_categories)
          .to contain_exactly(:dpsg_mitgliedschaft)
      end

      it "lets a Zweitmitgliedschaft provide an active membership" do
        expect(Group::Mitglieder::Zweitmitgliedschaft.provided_prerequisite_categories)
          .to contain_exactly(:aktive_mitgliedschaft)
      end

      it "requires a DPSG membership in any Stamm for a Zweitmitgliedschaft" do
        expect(Group::Mitglieder::Zweitmitgliedschaft.dependent_role_configurations)
          .to contain_exactly(have_attributes(category: :dpsg_mitgliedschaft, scope: :global,
            validate_past: false, on_uncovered: :cascade))
      end

      it "requires no prerequisite for Ordentliche- and Foerdermitgliedschaft" do
        [Group::Mitglieder::OrdentlicheMitgliedschaft,
          Group::Mitglieder::Foerdermitgliedschaft].each do |type|
          expect(type.dependent_role_configurations).to be_empty
        end
      end

      it "requires an active membership in the same Stamm for active roles in a Stamm" do
        [Group::StammGruppeBiber::Mitglied,
          Group::StammGruppeWoelflinge::Leitung,
          Group::StammGruppeRover::Hilfsleitung,
          Group::Stamm::Stammesmitgliederverwaltung,
          Group::Stamm::Bezirksdelegiert,
          Group::StammWoelflingsstufe::AKMitarbeiter,
          Group::StammIntaktPsychischeGesundheit::AKMitarbeiter].each do |type|
          expect(type.dependent_role_configurations).to depend_on_active_membership(:layer)
        end
      end

      it "requires any active membership for active roles above the Stamm" do
        [Group::BezirkPfadfinderstufe::AKMitarbeiter,
          Group::LandInternationales::Beauftragt,
          Group::Landesverband::Bundesdelegiert,
          Group::Bundesvorstand::Bundesvorsitz,
          Group::Bundesebene::Bundesmitarbeiter,
          Group::Bereich::Bereichsleitung].each do |type|
          expect(type.dependent_role_configurations).to depend_on_active_membership(:global)
        end
      end

      it "requires no membership for roles without active participation" do
        [Group::Bundesebene::MVAdmin,
          Group::Stamm::Kassenpruefung,
          Group::Stamm::ErfassungFuehrungszeugnis,
          Group::StammWoelflingsstufe::AKFreierMitarbeiter,
          Group::Bundesgeschaeftsstelle::Hauptamtlich,
          Group::Projekt::MitgliederverwaltungGrossprojekt,
          Group::PeopleManagers::Kontakt,
          Group::GruppierungsspezifischesGremium::Mitglied].each do |type|
          expect(type.dependent_role_configurations).to be_empty
        end
      end
    end

    describe "validation" do
      it "rejects a Foerdermitgliedschaft as prerequisite for an active role in the same Stamm" do
        Group::Mitglieder::Foerdermitgliedschaft
          .create!(person: admin, group: groups(:adler_mitglieder))
        role = Group::StammGruppePfadfinder::Leitung
          .new(person: admin, group: groups(:adler_pfadfinder))

        expect(role).not_to be_valid
        expect(role.errors[:base].first)
          .to include("Ordentliche Mitgliedschaft oder Zweitmitgliedschaft in Stamm Adler")
      end

      it "accepts a Zweitmitgliedschaft as prerequisite for an active role in its Stamm" do
        role = Group::Stamm::Stammesmitgliederverwaltung.new(person: member, group: groups(:biber))
        expect(role).not_to be_valid

        Group::Mitglieder::Zweitmitgliedschaft
          .create!(person: member, group: groups(:biber_mitglieder))

        expect(role).to be_valid
      end

      it "accepts a membership in any Stamm for an active role above the Stamm" do
        expect(Group::Bundesebene::Bundesmitarbeiter.new(person: member, group: groups(:root)))
          .to be_valid
        expect(Group::Bundesebene::Bundesmitarbeiter.new(person: admin, group: groups(:root)))
          .not_to be_valid
      end
    end

    it "shortens the active roles when the Ordentliche Mitgliedschaft ends" do
      mitarbeiter = Group::Bundesebene::Bundesmitarbeiter
        .create!(person: member, group: groups(:root))

      roles(:member_ordentliche_mitgliedschaft).update!(end_on: Date.current)

      expect(mitarbeiter.reload.end_on).to eq(Date.current)
      expect(roles(:member).reload.end_on).to eq(Date.current)
    end
  end
end
