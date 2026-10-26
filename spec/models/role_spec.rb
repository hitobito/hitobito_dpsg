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
          .new(person: people(:leader), group: adler_mitglieder)

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
    it "has consistent fixtures" do
      expect(roles(:member)).to be_valid
    end

    it "lets Ordentliche- and Foerdermitgliedschaft provide a Stamm and a DPSG membership" do
      [Group::Mitglieder::OrdentlicheMitgliedschaft,
        Group::Mitglieder::Foerdermitgliedschaft].each do |type|
        expect(type.provided_prerequisite_categories)
          .to contain_exactly(:stamm_mitgliedschaft, :dpsg_mitgliedschaft)
      end
    end

    it "lets a Zweitmitgliedschaft provide a Stamm membership" do
      expect(Group::Mitglieder::Zweitmitgliedschaft.provided_prerequisite_categories)
        .to contain_exactly(:stamm_mitgliedschaft)
    end

    it "requires a Stamm membership in the same Stamm for a Pfadfinder*in" do
      expect(Group::StammGruppePfadfinder::Mitglied.dependent_role_configurations)
        .to contain_exactly(have_attributes(category: :stamm_mitgliedschaft, scope: :layer,
          validate_past: false, on_uncovered: :cascade))
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
  end
end
